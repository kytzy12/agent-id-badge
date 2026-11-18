# Agent ID Badge — Binance Agent ID Hackathon

**Status: LIVE — contract deployed on BNB Chain, website live, project submitted to the hackathon.**
Submission deadline: **9 Dec 2026, 08:00 UTC (15:00 WIB)**.

## Links

- **Website (mint your free badge):** https://kytzy12.github.io/agent-id-badge/
- **Contract (BscScan):** https://bscscan.com/address/0x3DDe30F3e5E7D90191904CA34e1D42d29CF97f0A
- **X (updates):** https://x.com/lucky23334 — launch post: https://x.com/lucky23334/status/2123082106930897038
- **Demo video (60s):** https://kytzy12.github.io/agent-id-badge/VID-20261119-WA0634.mp4

## Apa ini?

**Agent ID Badge** adalah NFT badge GRATIS untuk pemegang Agent ID — dApp
identitas/achievement, BUKAN trading, BUKAN investasi.

- Satu badge per wallet.
- Hanya bisa di-mint oleh alamat yang memegang Agent ID.
- Mint gratis — kontrak tidak menerima atau menyimpan dana siapa pun.
  Pengguna hanya membayar gas BNB untuk transaksinya sendiri.
- Metadata sepenuhnya on-chain (base64 JSON + SVG inline). Tanpa IPFS,
  tanpa URL eksternal.

Tidak ada janji hadiah, tidak ada "passive income", tidak ada pengumpulan
seed phrase / private key / API secret. Nama proyek dan token tidak memakai
nama atau brand "Binance" / "BNB".

## Cara kerja Agent ID di proyek ini

Kontrak badge membaca kepemilikan Agent ID langsung dari kontrak Agent ID
resmi di BNB Chain mainnet:

- **Agent ID contract:** `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`
  (ERC-721, non-transferable, nama "SPACE ID Agent ID", simbol "AI")
- **Chain:** BNB Chain mainnet, **chainId 56**
- **Gate:** `mint()` memanggil `balanceOf(msg.sender)` di kontrak Agent ID.
  Mint hanya berhasil jika hasilnya `> 0`. Selain itu kontrak badge tidak
  memakai Agent ID untuk apa pun — tidak ada transfer, tidak ada approval,
  tidak ada pembacaan data lain.

Untuk form submission hackathon, deskripsi penggunaan Agent ID:

> "Agent ID Badge is an identity/achievement dApp on BNB Chain. It gates a
> free, one-per-wallet ERC-721 badge on Agent ID ownership: mint() succeeds
> only if the caller's address holds an Agent ID (balanceOf > 0 on the
> official Agent ID contract 0x60b9262456de011f7d15a54cdd8c48baaa8b022f).
> The contract never accepts or holds user funds; minting is free and the
> user only pays their own BNB gas. Metadata is fully on-chain (base64 JSON
> + inline SVG), no IPFS or external URLs."

## File

| File | Isi |
|---|---|
| `src/AgentIDBadge.sol` | Kontrak utama (ERC721 "Agent ID Badge", simbol `AIDB`) |
| `test/AgentIDBadge.t.sol` | 12 tes Foundry — semua PASS |
| `test/MockAgentID.sol` | Mock kontrak Agent ID — HANYA untuk tes lokal |
| `script/Deploy.s.sol` | Script deploy (forge script) |
| `script/LocalE2E.s.sol` | Tes end-to-end lokal di Anvil (bukan untuk mainnet) |
| `frontend/index.html` | Halaman web statis (GitHub Pages-ready) |
| `frontend/app.js` | Logika wallet + mint (ethers.js v6 via CDN) |
| `frontend/config.json` | Alamat kontrak (isi alamat badge SETELAH DEPLOY) |
| `foundry.toml` | Konfigurasi Foundry |

## Kontrak

### Fungsi utama

- `mint() payable returns (uint256)` — mint badge gratis untuk `msg.sender`.
  Syarat: (1) `msg.value == 0` (pembayaran ditolak), (2) pemanggil memegang
  Agent ID (`balanceOf > 0`), (3) pemanggil belum pernah mint (satu badge
  per wallet). Token ID berurutan mulai dari 1. Event: `BadgeMinted(minter, tokenId)`.
- `tokenURI(uint256)` — metadata on-chain: `data:application/json;base64,…`
  berisi `name`, `description`, `image` (SVG inline, base64), dan `attributes`.
- `hasMinted(address)`, `totalMinted()`, `nextTokenId`, `agentId` (immutable).

### Owner permissions — MINIMAL dan terdokumentasi

Owner (deployer, bisa di-`renounceOwnership`) hanya boleh:

| Fungsi | Efek |
|---|---|
| `setBadgeName(string)` | Mengubah nama badge di metadata |
| `setBadgeDescription(string)` | Mengubah deskripsi badge di metadata |

Owner **TIDAK BISA**:

- Mint badge ke alamat sembarang — tidak ada fungsi `mintTo` / admin-mint.
  `mint()` selalu mint ke `msg.sender` sendiri.
- Menarik dana — kontrak tidak menerima dana (`mint()` menolak `msg.value`,
  `receive()`/`fallback()` revert; saldo kontrak selalu 0).
- Pause, membekukan aset, mengubah pajak/fee — fitur itu tidak ada.
- Mengubah siapa yang boleh mint selain lewat kepemilikan Agent ID.

### Keamanan / kepatuhan aturan hackathon

- Tidak ada QR login / pairing code di web mana pun.
- Tidak ada bypass konfirmasi transaksi — semua transaksi ditandatangani
  dan dikonfirmasi pengguna di wallet mereka sendiri.
- Tidak ada transfer aset tanpa izin, tidak ada approval tak terbatas.
- Kontrak open-source, permission owner terdokumentasi di atas.
- Tidak memakai nama/brand "Binance" / "BNB" di nama token, proyek, atau domain.
- Tidak menjanjikan return / "passive income" / "dapat uang" di mana pun.
- Tidak mengumpulkan seed phrase, private key, API secret, atau pairing code.
- Agent ID TIDAK dipakai sebagai alat "melihat wallet orang lain berdasarkan nama".

## Tes (Foundry)

```bash
export PATH="$HOME/.foundry/bin:$PATH"
forge test
```

**Hasil: 12/12 PASS** (`test/AgentIDBadge.t.sol:AgentIDBadgeTest`):

| Tes | Hasil |
|---|---|
| `test_MintSucceedsForHolder` | PASS — holder mint, token #1 |
| `test_MintIdsAreSequential` | PASS — token #1, #2 berurutan |
| `test_MintFailsForNonHolder` | PASS — revert `NotAgentIDHolder` |
| `test_MintFailsAfterAgentIDRevoked` | PASS — holder yang Agent ID-nya dicabut gagal mint |
| `test_SecondMintFails` | PASS — revert `AlreadyMinted` |
| `test_TokenURIValid` | PASS — base64 JSON ter-decode, ada name/description/image SVG |
| `test_TokenURINonexistentReverts` | PASS — revert `NonexistentToken` |
| `test_OwnerCannotMintForOthers` | PASS — owner tanpa Agent ID gagal mint; owner dengan Agent ID hanya bisa mint untuk dirinya sendiri |
| `test_MintWithValueReverts` | PASS — revert `PaymentNotAccepted`, saldo kontrak 0 |
| `test_DirectTransferReverts` | PASS — kirim BNB langsung ditolak |
| `test_OwnerCanUpdateNameAndDescription` | PASS — metadata ikut berubah |
| `test_NonOwnerCannotUpdateMetadata` | PASS — non-owner revert |

Verifikasi end-to-end di Anvil lokal juga berhasil: deploy MockAgentID +
AgentIDBadge, mint token #1, `totalMinted() == 1`, `ownerOf(1) == minter`,
`tokenURI` ter-decode menjadi JSON valid + SVG 973 byte yang benar.

## Estimasi gas (dari `forge test --gas-report`)

| Operasi | Gas |
|---|---|
| Deploy kontrak | **3.522.180** |
| Ukuran kontrak | 17.031 byte (batas 24.576 — aman) |
| `mint()` (rata-rata / maks) | 82.224 / 121.119 |
| `tokenURI()` (view, gratis off-chain) | ±149.035 |

Perkiraan biaya deploy (gas × harga gas BSC):

| Harga gas | Biaya deploy |
|---|---|
| 1 gwei | ±0,0035 BNB |
| 3 gwei | ±0,0106 BNB |
| 5 gwei | ±0,0176 BNB |

Perkiraan biaya mint per pengguna: ±0,00008–0,00036 BNB (tergantung harga gas).
**Siapkan ±0,02 BNB untuk deploy agar aman.** Saldo wallet saat ini
(0,0002725 BNB, per 17 Nov 2026) TIDAK cukup untuk deploy — perlu top-up dulu.

## Cara deploy (mainnet) — LANGKAH UNTUK REVIEW, JANGAN DIJALANKAN TANPA KONFIRMASI

### Persiapan

1. Pastikan wallet deployer (owner) punya **±0,02 BNB** di BNB Chain mainnet.
2. Siapkan RPC BSC, misal `https://bsc-dataseed.bnbchain.org`.
3. (Opsional) API key BscScan untuk verifikasi source otomatis.

### Opsi A — Foundry (dari komputer)

```bash
export PATH="$HOME/.foundry/bin:$PATH"
cd ~/workspace/binance-agent-id-hackathon

# 1. Simulasi dulu (tanpa broadcast) — pastikan tidak ada error:
forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed.bnbchain.org

# 2. Deploy + verifikasi source di BscScan (TANYAKAN KONFIRMASI DULU):
forge script script/Deploy.s.sol \
  --rpc-url https://bsc-dataseed.bnbchain.org \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast --verify --verifier etherscan \
  --etherscan-api-key $BSCSCAN_API_KEY
```

Constructor args (sudah di-hardcode di `script/Deploy.s.sol`):
`_agentId = 0x60b9262456de011f7d15a54cdd8c48baaa8b022f`,
`initialOwner = <alamat deployer>`.

### Opsi B — Remix (dari HP / browser, tanpa komputer)

1. Buka https://remix.ethereum.org, buat file `AgentIDBadge.sol`, paste isi
   `src/AgentIDBadge.sol` + file OpenZeppelin yang di-import (atau pakai
   import URL GitHub OpenZeppelin v5.0.2).
2. Compile (Solidity 0.8.20+, optimizer default).
3. Di tab "Deploy & Run", pilih "Injected Provider" (hubungkan Binance Wallet
   / MetaMask, jaringan BNB Chain Mainnet).
4. Deploy dengan constructor args:
   `_agentId = 0x60b9262456de011f7d15a54cdd8c48baaa8b022f`,
   `initialOwner = <alamat wallet kamu>`.
5. Verifikasi source di BscScan (menu "Verify & Publish", paste source + pilih
   compiler yang sama).

### Catatan tentang Binance Agentic Wallet (`baw` CLI)

`baw` CLI tidak punya perintah deploy kontrak — `baw contract-call` hanya
untuk memanggil kontrak yang SUDAH ada. Jadi deploy memakai Opsi A atau B.
Setelah kontrak ter-deploy, fungsi owner (misal `setBadgeName`) bisa
dijalankan lewat `baw` dengan alur preview → konfirmasi → execute:

```bash
baw wallet settings --json   # pastikan devMode.enabled=true
baw contract-call preview --to <ALAMAT_BADGE> --data <ENCODED_CALLDATA>
# ...cek preview, konfirmasi, lalu:
baw contract-call execute --requestId <REQUEST_ID>
```

### Setelah deploy

1. Catat alamat kontrak badge.
2. Isi alamat itu di `frontend/config.json` (`badgeContractAddress`) dan di
   `frontend/app.js` (konstanta `BADGE_CONTRACT_ADDRESS`).
3. Verifikasi di BscScan: buka halaman kontrak → tab "Contract" harus
   "Verified" (centang hijau), dan baca `agentId()` — harus
   `0x60b9262456de011f7d15a54cdd8c48baaa8b022f`.
4. Tes mint dengan wallet pemegang Agent ID (biaya gas ±0,0001–0,0004 BNB).
5. Deploy frontend ke GitHub Pages (lihat bawah).
6. Submit ke hackathon: nama proyek, website, alamat kontrak, deskripsi
   penggunaan Agent ID (lihat atas), dan alamat penerima hadiah.

## Cara jalanin frontend lokal

```bash
cd frontend
python3 -m http.server 8000
# buka http://localhost:8000 di browser
```

Untuk GitHub Pages: push folder `frontend/` ke repo GitHub, aktifkan Pages
(Settings → Pages → Branch: main, folder: `/frontend` atau root repo yang
hanya berisi file frontend). Tidak ada build step.

**Sebelum frontend bisa dipakai, isi dulu alamat kontrak badge** di
`frontend/config.json` dan `frontend/app.js` (lihat "Setelah deploy" di atas).
Selama alamat masih `0x0000…0000`, tombol mint non-aktif dan halaman
menampilkan peringatan.

## Batasan / yang BELUM dilakukan

- Kontrak BELUM di-deploy ke mainnet (sengaja — butuh review + BNB top-up).
- Frontend BELUM di-host (butuh alamat kontrak dulu).
- TIDAK ADA SUBMIT ke hackathon (langkah pemilik proyek setelah review).
- Mendapatkan 30+ alamat Agent ID yang berinteraksi adalah syarat kelayakan
  Innovation Award — itu pekerjaan promosi/komunitas, bukan bagian dari build ini.
- Ranking Growth Award dihitung dari jumlah alamat Agent ID yang berinteraksi,
  volume, dan jumlah transaksi on-chain selama periode submission.
