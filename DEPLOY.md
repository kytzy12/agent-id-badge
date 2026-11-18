# Deploy — Agent ID Badge (Binance Agent ID Hackathon)

## Preview (2026-11-18 ~23:06 WIB) — SUCCEEDED
- requestId: b38c49324b8445fb90812cce5b4f4cea
- expiresAt (ms): 1795018300517
- from (John's wallet): 0x02962133fE4ed72B5d194c314348aa6D8Bcb6525
- to (CREATE2 factory): 0x4e59b44847b379578588920cA78FbF26c0B4956C
- value: 0
- inputData: 32-byte zero salt + init code (17,031 bytes) — file /tmp/badge-calldata.txt
- parsedTx: ContractInteraction, contractAddress = factory
- simulation: code 000000000, error null — PASSED
- risks: riskDetails [], riskBehaviors [], addresses {} — NONE flagged
- requireConfirmation: false (direct broadcast)
- gasLimit: null (backend estimates)

## Expected deployed contract address (CREATE2, salt 0)
0x3DDe30F3e5E7D90191904CA34e1D42d29CF97f0A

## Cost estimate (parent calculation, NOT from preview)
- ~3.85M gas total; at low gas 0.051 gwei ≈ 0.000196 BNB
- John's balance: 0.0002725 BNB → leaves ~0.000077 BNB
- At medium gas 0.072 gwei ≈ 0.000277 BNB — just OVER balance (preview must be re-run if it fails)

## Execute (ONLY after John's explicit confirmation of the preview)
baw contract-call execute --requestId b38c49324b8445fb90812cce5b4f4cea --json

## After execute
1. Get txHash from execute output.
2. Verify on BscScan that the contract deployed at 0x3DDe30F3e5E7D90191904CA34e1D42d29CF97f0A.
3. Verify source on BscScan.
4. Fill contract address + website in SUBMISSION.md and frontend/config.json.
5. Submit project to the hackathon.
