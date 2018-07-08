package cs441641.miners;

import cs441641.blockchain.Block;
import cs441641.blockchain.NetworkStatistics;



public class SelfishMiner extends BaseMiner implements Miner {
    private Block myHead;
    private Block currentHead;
    private double totalHashRate;
    private double myHashRate;
    private int leadingBlock = -1;

    public SelfishMiner(String id, int hashRate, int connectivity) {
        super(id, hashRate, connectivity);
    }

    @Override
    public Block currentlyMiningAt() {
        return myHead;
    }

    @Override
    public Block currentHead() {
        return currentHead;
    }

    @Override
    public void blockMined(Block block, boolean isMinerMe) {
    	myHashRate = getHashRate();
    	//selfish mining is an improvement over the default strategy if ¦Á > 0.25
        if (myHashRate / totalHashRate > 0.25) {
            if (isMinerMe) {
            	leadingBlock = myHead.getHeight() - currentHead.getHeight();
                if (block.getHeight() > myHead.getHeight()) {
                    this.myHead = block;
                }
            } else {
                if (block.getHeight() > currentHead.getHeight()) {
                	currentHead = block;
                	leadingBlock = myHead.getHeight() - currentHead.getHeight();
                    if (leadingBlock < 0) {
                        myHead = currentHead;
                    }
                    if (leadingBlock == 1 || leadingBlock == 0) {
                    	currentHead = myHead;
                    }
                }
            }
        }

      //default strategy if ¦Á < 0.25
        else {
            if(isMinerMe) {
                if (block.getHeight() > myHead.getHeight()) {
                    myHead = block;
                    currentHead = block;
                }
            }

            else{
                 if (block.getHeight() > myHead.getHeight()) {
                	 myHead = block;
                	 currentHead = block;
                }
            }

        }
    }

    @Override
    public void initialize(Block genesis, NetworkStatistics networkStatistics) {
        this.myHead = genesis;
        this.currentHead = genesis;
        this.leadingBlock = -1;
        totalHashRate = 1;
    }

    @Override
    public void networkUpdate(NetworkStatistics statistics) {
        totalHashRate = statistics.getTotalHashRate();
    }
}




