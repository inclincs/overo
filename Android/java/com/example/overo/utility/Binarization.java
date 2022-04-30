package com.example.overo.utility;

import java.nio.ByteOrder;

public class Binarization {
    public static byte[] binarize(double value) {
        long l = Double.doubleToLongBits(value);

        return new byte[] {
                (byte) ((l) & 0xFF),
                (byte) ((l >> 8) & 0xFF),
                (byte) ((l >> 16) & 0xFF),
                (byte) ((l >> 24) & 0xFF),
                (byte) ((l >> 32) & 0xFF),
                (byte) ((l >> 40) & 0xFF),
                (byte) ((l >> 48) & 0xFF),
                (byte) ((l >> 56) & 0xFF),

        };
    }

    public static byte[] binarize(double[] value) {
        byte[] result = new byte[value.length * 8];

        for (int i = 0; i < value.length; i++) {
            byte[] binarized = binarize(value[i]);

            System.arraycopy(binarized, 0, result, i * 8, binarized.length);
        }

        return result;
    }

    public static double[] toDouble(byte[] bytes) {
        double[] values = new double[bytes.length / 8];

        for (int i = 0; i < values.length; i++) {
            double value = .0;

            for (int j = 0; j < 8; j++) {
                value += (bytes[j] << (j * 8));
            }

            values[i] = value;
        }

        return values;
    }

    public static long[] toLong(byte[] bytes) {
        long[] values = new long[bytes.length / 8];

        for (int i = 0; i < values.length; i++) {
            long value = 0L;

            for (int j = 0; j < 8; j++) {
                value += (bytes[j] << (j * 8));
            }

            values[i] = value;
        }

        return values;
    }

    private static final char[] LOOKUP_TABLE_LOWER = new char[]{0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66};
    private static final char[] LOOKUP_TABLE_UPPER = new char[]{0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46};

    public static String encode(byte[] byteArray, boolean upperCase, ByteOrder byteOrder) {

        // our output size will be exactly 2x byte-array length
        final char[] buffer = new char[byteArray.length * 2];

        // choose lower or uppercase lookup table
        final char[] lookup = upperCase ? LOOKUP_TABLE_UPPER : LOOKUP_TABLE_LOWER;

        int index;
        for (int i = 0; i < byteArray.length; i++) {
            // for little endian we count from last to first
            index = (byteOrder == ByteOrder.BIG_ENDIAN) ? i : byteArray.length - i - 1;

            // extract the upper 4 bit and look up char (0-A)
            buffer[i << 1] = lookup[(byteArray[index] >> 4) & 0xF];
            // extract the lower 4 bit and look up char (0-A)
            buffer[(i << 1) + 1] = lookup[(byteArray[index] & 0xF)];
        }
        return new String(buffer);
    }

    public static String encode(byte[] byteArray) {
        return encode(byteArray, false, ByteOrder.BIG_ENDIAN);
    }
}
