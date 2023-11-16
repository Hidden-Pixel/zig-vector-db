#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <emmintrin.h>

#define MAX_POINTS 1000

typedef struct point {
    double coords[2];
} Point;

__m128d distance(Point a, Point b) {
    __m128d va = _mm_loadu_pd(a.coords);
    __m128d vb = _mm_loadu_pd(b.coords);
    __m128d result = _mm_sub_pd(va, vb);
    result = _mm_mul_pd(result, result);
    return result;
}

Point centroid(Point *cluster, int size) {
    __m128d sum = _mm_setzero_pd();

    for (int i = 0; i < size; ++i) {
        __m128d v = _mm_loadu_pd(cluster[i].coords);
        sum = _mm_add_pd(sum, v);
    }

    __m128d divisor = _mm_set1_pd(size);
    sum = _mm_div_pd(sum, divisor);

    Point result;
    _mm_storeu_pd(result.coords, sum);
    return result;
}

Point *kMeans(Point *data, int num_points, int k, double epsilon) {
    // Initialize centroids randomly
    Point *centroids = (Point *)malloc(sizeof(Point) * k);
    for (int i = 0; i < k; ++i) {
        centroids[i] = data[rand() % num_points];
    }

    while (true) {
        // Create clusters
        Point clusters[k][MAX_POINTS];
        int cluster_sizes[k];

        for (int i = 0; i < k; ++i) {
            cluster_sizes[i] = 0;
        }

        for (int i = 0; i < num_points; ++i) {
            // Find closest centroid for this data point
            int belongs_to = 0;
            double min_dist = INFINITY;

            for (int j = 0; j < k; ++j) {
                __m128d dist = distance(data[i], centroids[j]);
                dist = _mm_sqrt_pd(dist);

                if (_mm_cvtsd_f64(dist) < min_dist) {
                    min_dist = _mm_cvtsd_f64(dist);
                    belongs_to = j;
                }
            }

            // Add this data point to the cluster of the closest centroid
            clusters[belongs_to][cluster_sizes[belongs_to]++] = data[i];
        }

        // Find new centroids
        Point new_centroids[k];
        for (int i = 0; i < k; ++i) {
            new_centroids[i] = centroid(clusters[i], cluster_sizes[i]);
        }

        // Check if centroids have moved significantly
        int moved = 0;
        for (int i = 0; i < k; ++i) {
            __m128d dist = distance(centroids[i], new_centroids[i]);
            dist = _mm_sqrt_pd(dist);

            if (_mm_cvtsd_f64(dist) > epsilon) {
                moved = 1;
                break;
            }
        }

        // If centroids have not moved significantly, we're done
        if (!moved) {
            return centroids;
        }

        // Otherwise, continue with the new centroids
        for (int i = 0; i < k; ++i) {
            centroids[i] = new_centroids[i];
        }
    }
}

int main() 
{
    // Test the kMeans function
    Point testData[] = {
        {1.0, 1.0},
        {2.0, 2.0},
        {9.0, 8.0},
        {10.0, 9.0},
    };

    int num_points = sizeof(testData) / sizeof(testData[0]);
    int k = 2;
    double epsilon = 0.001;

    Point *centroids = kMeans(testData, num_points, k, epsilon);
    // Print the resulting clusters
    for (int i = 0; i < k; ++i) {
        printf("Cluster[%d] centroid: { %f, %f }\n", i, centroids[i].coords[0], centroids[i].coords[1]);
        printf("Cluster %d: [", i + 1);
        for (int j = 0; j < num_points; ++j) {
            if (j < num_points - 1) {
                printf("{%.2f, %.2f}, ", testData[j].coords[0], testData[j].coords[1]);
            } else {
                printf("{%.2f, %.2f}", testData[j].coords[0], testData[j].coords[1]);
            }
        }
        printf("]\n");
    }

    return 0;
}

