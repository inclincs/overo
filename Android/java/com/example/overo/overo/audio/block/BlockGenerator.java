package com.example.overo.overo.audio.block;

import androidx.annotation.NonNull;

import java.util.Iterator;

public class BlockGenerator implements Iterable<Block>, Iterator<Block> {

    double[] samples;
    int blockSize;

    int blockCount;
    int currentBlockIndex;

    public BlockGenerator(double[] samples, int blockSize) {
        this.samples = samples;
        this.blockSize = blockSize;

        this.blockCount = samples.length / blockSize;
        this.currentBlockIndex = 0;
    }

    @Override
    public boolean hasNext() {
        return this.currentBlockIndex < this.blockCount;
    }

    @Override
    public Block next() {
        int block_index = this.currentBlockIndex;
        double[] block_samples = new double[this.blockSize];

        if (this.blockSize >= 0) {
            int startIndex = this.blockSize * this.currentBlockIndex;

            System.arraycopy(this.samples, startIndex, block_samples, 0, this.blockSize);
        }

        Block block = new Block(block_index, block_samples);

        currentBlockIndex++;

        return block;
    }

    @NonNull
    @Override
    public Iterator<Block> iterator() {
        return this;
    }
}
