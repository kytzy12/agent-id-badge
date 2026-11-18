/* Agent ID Badge — frontend logic (ethers.js v6, no build step).
 *
 * Flow:
 *   1. Connect Wallet (MetaMask / Binance Wallet / any injected EIP-1193 wallet).
 *   2. Check Agent ID: balanceOf(wallet) on the Agent ID contract > 0.
 *   3. Check badge status: hasMinted(wallet) on the badge contract.
 *   4. If holder && !minted -> enable "Mint Badge Gratis" (free mint, user pays only their own BNB gas).
 *
 * No funds are ever sent to the contract: mint() is free and rejects value.
 * Contract addresses are loaded from config.json; BADGE_CONTRACT_ADDRESS
 * below is the fallback — ISI SETELAH DEPLOY (paste the deployed address).
 */

"use strict";

// ---------------------------------------------------------------------------
// Config — ISI SETELAH DEPLOY
// ---------------------------------------------------------------------------
// Paste the deployed AgentIDBadge contract address here (BNB Chain mainnet).
// If config.json exists next to this file and contains a non-zero address,
// it takes precedence over this constant.
const BADGE_CONTRACT_ADDRESS = "0x3DDe30F3e5E7D90191904CA34e1D42d29CF97f0A"; // Deployed 2026-11-18, tx 0xae9c8b54ebce535a50e9025ce58fd85efedf117e1385eca1f3b39f48d53289bf

// Agent ID contract (ERC-721, non-transferable) — BNB Chain mainnet.
const AGENT_ID_CONTRACT_ADDRESS = "0x60b9262456de011f7d15a54cdd8c48baaa8b022f";

const EXPECTED_CHAIN_ID = 56; // BNB Chain mainnet
const BSCSCAN_TX = "https://bscscan.com/tx/";
const BSCSCAN_ADDRESS = "https://bscscan.com/address/";

// Minimal ABIs — only the functions this page uses.
const AGENT_ID_ABI = ["function balanceOf(address account) view returns (uint256)"];
const BADGE_ABI = [
  "function mint() payable returns (uint256)",
  "function hasMinted(address account) view returns (bool)",
  "function totalMinted() view returns (uint256)",
  "function tokenURI(uint256 tokenId) view returns (string)",
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function ownerOf(uint256 tokenId) view returns (address)",
];

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
let provider = null;
let signer = null;
let userAddress = null;
let badgeAddress = BADGE_CONTRACT_ADDRESS;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const $ = (id) => document.getElementById(id);

function setStatus(msg, kind) {
  const el = $("status");
  el.textContent = msg;
  el.className = "status " + (kind || "");
}

function shortAddr(addr) {
  return addr ? addr.slice(0, 6) + "…" + addr.slice(-4) : "";
}

async function loadConfig() {
  try {
    const res = await fetch("./config.json", { cache: "no-store" });
    if (!res.ok) return;
    const cfg = await res.json();
    if (cfg.badgeContractAddress && cfg.badgeContractAddress !== "0x0000000000000000000000000000000000000000") {
      badgeAddress = cfg.badgeContractAddress;
    }
  } catch (e) {
    // config.json unreadable (e.g. opened via file://) — fall back to the
    // BADGE_CONTRACT_ADDRESS constant above.
    console.warn("config.json tidak bisa dibaca, memakai konstanta di app.js:", e);
  }
}

function badgeConfigured() {
  return badgeAddress && badgeAddress !== "0x0000000000000000000000000000000000000000";
}

// ---------------------------------------------------------------------------
// Wallet connection
// ---------------------------------------------------------------------------
async function connectWallet() {
  if (!window.ethereum) {
    setStatus("Wallet tidak ditemukan. Pasang MetaMask atau Binance Wallet, lalu refresh halaman ini.", "error");
    return;
  }
  try {
    setStatus("Meminta koneksi wallet…", "");
    provider = new ethers.BrowserProvider(window.ethereum);
    const accounts = await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    userAddress = accounts[0];

    $("connectBtn").textContent = "Terhubung: " + shortAddr(userAddress);
    $("connectBtn").disabled = true;
    $("walletLine").textContent = "Wallet: " + userAddress;
    $("walletLine").style.display = "block";

    await checkNetwork();
    await refreshStatus();
  } catch (err) {
    console.error(err);
    setStatus("Koneksi dibatalkan atau gagal: " + (err && err.message ? err.message : err), "error");
  }
}

async function checkNetwork() {
  const net = await provider.getNetwork();
  const chainId = Number(net.chainId);
  if (chainId !== EXPECTED_CHAIN_ID) {
    setStatus(
      "Kamu sedang di jaringan " + net.name + " (chainId " + chainId + "). " +
      "Pindah ke BNB Chain Mainnet (chainId 56) untuk mint badge.",
      "warn"
    );
    $("switchBtn").style.display = "inline-block";
  } else {
    $("switchBtn").style.display = "none";
  }
}

async function switchNetwork() {
  try {
    await provider.send("wallet_switchEthereumChain", [{ chainId: "0x38" }]); // 56 = 0x38
    setStatus("Jaringan sudah BNB Chain Mainnet.", "ok");
    await refreshStatus();
  } catch (err) {
    console.error(err);
    setStatus(
      "Gagal pindah jaringan. Tambahkan BNB Chain Mainnet secara manual di wallet kamu (chainId 56, RPC https://bsc-dataseed.bnbchain.org).",
      "error"
    );
  }
}

// ---------------------------------------------------------------------------
// Status checks
// ---------------------------------------------------------------------------
async function refreshStatus() {
  if (!provider || !userAddress) return;
  try {
    const agentId = new ethers.Contract(AGENT_ID_CONTRACT_ADDRESS, AGENT_ID_ABI, provider);
    const agentBalance = await agentId.balanceOf(userAddress);
    const hasAgentId = agentBalance > 0n;

    $("agentIdLine").textContent = hasAgentId
      ? "✅ Kamu memegang Agent ID (balance: " + agentBalance.toString() + ")."
      : "❌ Wallet ini belum memegang Agent ID. Badge hanya bisa di-mint oleh pemegang Agent ID.";
    $("agentIdLine").className = hasAgentId ? "line ok" : "line error";
    $("agentIdLine").style.display = "block";

    if (!badgeConfigured()) {
      setStatus("Kontrak badge belum di-deploy / alamat belum diisi (lihat config.json). Mint belum bisa dilakukan.", "warn");
      $("mintBtn").disabled = true;
      return;
    }

    const badge = new ethers.Contract(badgeAddress, BADGE_ABI, provider);
    const minted = await badge.hasMinted(userAddress);
    const total = await badge.totalMinted();
    $("mintedLine").textContent = "Total badge yang sudah di-mint: " + total.toString();
    $("mintedLine").style.display = "block";

    if (minted) {
      $("badgeLine").textContent = "🎉 Kamu sudah punya badge ini (satu badge per wallet).";
      $("badgeLine").className = "line ok";
      $("badgeLine").style.display = "block";
      $("mintBtn").disabled = true;
      setStatus("Kamu sudah mint badge. Cek badge kamu di BscScan (tab Token Holdings / NFT).", "ok");
      return;
    }

    if (hasAgentId) {
      setStatus("Kamu bisa mint badge gratis sekarang. Mint gratis — kamu hanya bayar gas BNB sendiri.", "ok");
      $("mintBtn").disabled = false;
    } else {
      setStatus("Mint belum bisa: wallet ini belum memegang Agent ID.", "warn");
      $("mintBtn").disabled = true;
    }
  } catch (err) {
    console.error(err);
    setStatus("Gagal membaca status: " + (err && err.message ? err.message : err), "error");
  }
}

// ---------------------------------------------------------------------------
// Mint
// ---------------------------------------------------------------------------
async function mintBadge() {
  if (!signer || !userAddress) {
    setStatus("Hubungkan wallet dulu.", "error");
    return;
  }
  if (!badgeConfigured()) {
    setStatus("Alamat kontrak badge belum diisi.", "error");
    return;
  }
  const badge = new ethers.Contract(badgeAddress, BADGE_ABI, signer);
  try {
    $("mintBtn").disabled = true;
    setStatus("Mengirim transaksi mint… (cek dan konfirmasi di wallet kamu)", "");
    const tx = await badge.mint(); // free mint — no value attached
    setStatus("Transaksi dikirim: " + tx.hash + " — menunggu konfirmasi…", "");
    $("txLine").innerHTML =
      'Transaksi: <a href="' + BSCSCAN_TX + tx.hash + '" target="_blank" rel="noopener">' + tx.hash + "</a>";
    $("txLine").style.display = "block";
    const receipt = await tx.wait();
    if (receipt.status === 1) {
      setStatus("✅ Badge berhasil di-mint! Selamat — badge kamu sudah ada di wallet.", "ok");
      $("badgeLine").textContent = "🎉 Badge berhasil di-mint. Lihat di BscScan: " + BSCSCAN_ADDRESS + userAddress;
      $("badgeLine").className = "line ok";
      $("badgeLine").style.display = "block";
    } else {
      setStatus("Transaksi gagal (status 0). Coba lagi.", "error");
    }
    await refreshStatus();
  } catch (err) {
    console.error(err);
    const msg = err && err.code === "ACTION_REJECTED"
      ? "Transaksi dibatalkan di wallet."
      : "Mint gagal: " + (err && err.reason ? err.reason : err && err.message ? err.message : err);
    setStatus(msg, "error");
    $("mintBtn").disabled = false;
  }
}

// ---------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------
window.addEventListener("DOMContentLoaded", async () => {
  await loadConfig();
  $("connectBtn").addEventListener("click", connectWallet);
  $("mintBtn").addEventListener("click", mintBadge);
  $("switchBtn").addEventListener("click", switchNetwork);

  if (badgeConfigured()) {
    const note = $("contractNote");
    note.innerHTML = '<a href="' + BSCSCAN_ADDRESS + badgeAddress + '" target="_blank" rel="noopener">' + badgeAddress + "</a>";
  } else {
    setStatus("Kontrak badge belum di-deploy / alamat belum diisi. Hubungkan wallet untuk cek status Agent ID kamu.", "warn");
  }

  // If a wallet is already connected, react to account / chain changes.
  if (window.ethereum) {
    window.ethereum.on("accountsChanged", () => window.location.reload());
    window.ethereum.on("chainChanged", () => window.location.reload());
  }
});
