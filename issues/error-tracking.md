# Error Tracking

## Issue-1
```json
time="2021-07-26 21:47:00" level=error msg="Failed to request block from beacon node" blockSlot=4396 error="rpc error: code = Internal desc = Could not compute state root: could not calculate state root at slot 0: could not process block: could not process block header: parent root 0x1d6fd110ff1185576ef81f6110001bc75ed0818494cba6b4d5877c084c1c3743 does not match the latest block header signing root in state 0x64589bd9ec8dbdfbef5cdd8b82ccb066152db86ec433e8af20cd661a05b0b70a" prefix=validator pubKey=0xb5a0541de17c
```

**Cause:**
- fastszz version duplication in go mod file.

## Issue-2
```json
CRIT [07-27|21:22:33.876] Orchestrator is offline for too long. Please check your connection 
```

**Cause:**
- 2 ^ 32 == 34 retries for establishing orchestrator connection after 5 sec interval


## Issue-2
```json
time="2021-07-27 23:38:27" level=debug msg="checking pending queue length before preparing block" prefix="rpc/validator" slot=11
time="2021-07-27 23:38:27" level=error msg="Could not get last block by earliest valid time" error="not found" prefix="rpc/validator"
time="2021-07-27 23:38:27" level=warning msg="Beacon Node is no longer connected to an ETH1 chain, so ETH1 data votes are now random." prefix="rpc/validator"
```

**Cause:**
- 