package main

import (
	"fmt"
	"math/rand"
	"time"

	"example/kmeans"
)

func main() {
	// Initialize data
	data := GenerateVectors(512, 10000)
	// Perform KMeans
	clusters, centroids := kmeans.KMeans(data, 2, .001)
	_ = centroids
	// fmt.Println("centroids", centroids)

	// Print clusters
	fmt.Println("")
	for i, cluster := range clusters {
		_ = i
		// fmt.Println("Cluster info", i, cluster)
		fmt.Println("")
		for _, point := range cluster {
			_ = point
			// fmt.Printf("Point: %v\n", point)
		}
	}
}

// GenerateVectors generates a slice of Vector with given vector length and total vectors
func GenerateVectors(vectorLength int, totalVectors int) []kmeans.Vector {
	rand.Seed(time.Now().UnixNano())
	data := make([]kmeans.Vector, totalVectors)

	for i := 0; i < totalVectors; i++ {
		vector := make(kmeans.Vector, vectorLength)

		for j := 0; j < vectorLength; j++ {
			vector[j] = rand.Float64() * 10 // Generate a random float between 0 and 10
		}

		data[i] = vector
	}

	return data
}
