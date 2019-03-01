package amirz.dngprocessor.math;

public class Histogram {
    public final float[] sigma = new float[3];
    public final float[] zRange = new float[2];
    public final float[] hist;

    public Histogram(float[] f, int whPixels, float[] stretchPerc) {
        int histBins = 512;
        int[] hist = new int[histBins];

        // Loop over all values
        for (int i = 0; i < f.length; i += 4) {
            for (int j = 0; j < 3; j++) {
                sigma[j] += f[i + j];
            }

            int bin = (int) (f[i + 3] * histBins);
            if (bin >= histBins) bin = histBins - 1;
            hist[bin]++;
        }

        for (int j = 0; j < 3; j++) {
            sigma[j] /= whPixels;
        }

        float[] cumulativeHist = new float[histBins + 1];
        for (int i = 1; i < cumulativeHist.length; i++) {
            cumulativeHist[i] = cumulativeHist[i - 1] + hist[i - 1];
        }

        float max = cumulativeHist[histBins];
        //int minZ = 0;
        //int maxZ = histBins;
        for (int i = 0; i < cumulativeHist.length; i++) {
            cumulativeHist[i] /= max;
            /*
            if (cumulativeHist[i] < stretchPerc[0]) {
                minZ = i;
            } else if (cumulativeHist[i] > stretchPerc[1]) {
                maxZ = Math.min(maxZ, i);
            }*/
        }

        float[] gauss = { 0.06136f, 0.24477f, 0.38774f, 0.24477f, 0.06136f };
        this.hist = Convolve.conv(cumulativeHist, gauss, true);

        //float zRangeStrength = 0.67f;
        //zRange[0] = zRangeStrength * ((float) minZ) / histBins;
        //zRange[1] = zRangeStrength * ((float) maxZ) / histBins + (1f - zRangeStrength);
        zRange[0] = 0.f;
        zRange[1] = 1.f;
    }
}
