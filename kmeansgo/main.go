package main

import (
	"fmt"

	"example/kmeans"
)

func main() {
	// Initialize data
	data := []kmeans.Point{
		{1, 2},
		// {1.5, 1.8},
		// {2, 2},
		// {8, 8},
		// {8, 9},
		{9, 11},
	}

	_ = data

	// Perform KMeans
	clusters, centroids := kmeans.KMeans(data, 2, .001)
	_ = centroids
	// fmt.Println("centroids", centroids)

	// Print clusters
  fmt.Println("")
	for i, cluster := range clusters {
		fmt.Println("Cluster info", i, cluster)
		for _, point := range cluster {
			fmt.Printf("Point: %v\n", point)
		}
	}
}
