# Issues when running Lukso network

## Issues:

1. pandora discard propagated block when running in fast sync(default syncing mode) mode.
2. getting issue in orchestrator client.


@Fabian we have got 3 issues so far:
- ParentHash mis-match in getWork api(Resolved): 
	Behaviour of the issue:
		- Failed block production
	Cause of the issue:
		- Pandora was put BLS signature in `extraData` field as well as in it also put 32 bytes of BLS signature in `MixDigest`.
		- validator generated hash of header with signature in `extraData` field(have no any idea about `MixDigest` alteration) thus the `parentHash` was mis-matched in pandora when producing next.
	Resolution:
		- Removed the alteration of `MixDigest` in pandora.

- Forking issue(orchestrator is making decisions after a long time) (Not Resolved):
	Behaviour of the issue:
		- Block producer vanguard and pandora node get verified status for a certain block but other syncing peers get pending status after sending downloaded block to orchestrator in time. So the syncing van and pan nodes discard the block after waiting for 20 sec. Thus they are getting forked.
		- Only one node is progressing and other nodes can not progress due to get pending status from orchestrator.
	Cause of the issue:
		- Unknown.
	Resolution:
		- Re-implementated consensus service in orchestrator.
		- Now orchestrator gives proper status to van and pan

- Invalid slot number in Pandora Client
	Behaviour of the issue:
		- Pandora generates slot number which is less than 1 of valid slot.
		- Validator discard the pandora header beacuse of invalid slot number.
	Cause of the issue:
		- Pandora triggers Re-submit work hook every 3 sec and orchestrator substract 3 from `EpochStartTime` and send it to pandora.
		- Pandora calculates slot number based on header time and `EpochStratTime` using this method `NewPandoraExtraData()`. And it calculates invalid slot number.
	Resolution:
		- Have given a fix in pandora client. But need to have proper implementation.

- Signature Verification failed in Pandora Client
	Behaviour of the issue:
		- Pandora 
