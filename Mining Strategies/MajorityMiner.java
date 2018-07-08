package cs441641.miners;

import cs441641.blockchain.Block;
import cs441641.blockchain.NetworkStatistics;

public class MajorityMiner extends BaseMiner implements Miner{
	private Block currentHead;
	private int majorityMinerHashRate, totalHashRate;
	
	public MajorityMiner(String id, int hashRate, int connectivity) {
		super(id, hashRate, connectivity);
	}

	@Override
	public Block currentlyMiningAt() {
		// TODO Auto-generated method stub
		return currentHead;
	}

	@Override
	public Block currentHead() {
		// TODO Auto-generated method stub
		return currentHead;
	}

	@Override
	public void blockMined(Block block, boolean isMinerMe) {
		// TODO Auto-generated method stub
		majorityMinerHashRate = getHashRate();
		
		//if miner is not our and lost majority, accept the block
		if (!isMinerMe) {
			if (0.5 * totalHashRate > majorityMinerHashRate)
				this.currentHead = block;
		}
		
		//if miner is our, update the head
		else {
			this.currentHead = block;
		}
		
		
	}

	@Override
	public void networkUpdate(NetworkStatistics statistics) {
		// constantly update the network total hash rate and store it
		this.totalHashRate = statistics.getTotalHashRate();
	}

	@Override
	public void initialize(Block genesis, NetworkStatistics statistics) {
		// TODO Auto-generated method stub
		this.currentHead = genesis;
	}
	
	
	
	
}
