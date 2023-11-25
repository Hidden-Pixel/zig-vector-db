package kmeans
//
// import (
// 	"fmt"
// 	"math"
// 	// "math/rand"
// )
//
// type Point struct {
// 	X float64
// 	Y float64
// }
//
// func KMeans(data []Point, k int, epsilon float64) ([][]Point ,[]Point){
// 	// Initialize centroids randomly
// 	// centroids := make([]Point, k)
// var centroids []Point
// 	// for i := range centroids {
// 	// 	centroids[i] = data[rand.Intn(len(data))]
//  //    fmt.Println(centroids[i])
// 	// }
//
//   centroids = append(centroids, Point{2,2})
//   centroids = append(centroids, Point{8,9})
// 	for {
// 		// Create clusters
// 		clusters := make([][]Point, k)
// 		for _, point := range data {
// 			// Find closest centroid for this data point
// 			belongsTo := 0
// 			minDist := math.Inf(1)
// 			for i, centroid := range centroids {
// 				dist := distance(point, centroid)
//         fmt.Println("centroid", centroid,"point",point,"dist", dist)
// 				if dist < minDist {
// 					minDist = dist
// 					belongsTo = i
// 				}
// 			}
// 			// Add this data point to the cluster of the closest centroid
// 			clusters[belongsTo] = append(clusters[belongsTo], point)
// 		}
//     // fmt.Println("CLUSTERS",clusters)
// 		// for i, cluster := range clusters {
//       // fmt.Println("cluster", i,"item=",cluster)
//     // }
// 		// Find new centroids
// 		newCentroids := make([]Point, k)
// 		for i, cluster := range clusters {
// 			newCentroids[i] = centroid(cluster)
//       // fmt.Println("new centroid", newCentroids[i])  
// 		}
//
// 		// Check if centroids have moved significantly
// 		moved := false
// 		for i := range centroids {
// 			if distance(centroids[i], newCentroids[i]) > epsilon {
// 				moved = true
// 				break
// 			}
// 		}
//
// 		// If centroids have not moved significantly, we're done
// 		if !moved {
// 			return clusters,newCentroids
// 		}
//
// 		// Otherwise, continue with the new centroids
// 		centroids = newCentroids
// 	}
// }
//
// func distance(a, b Point) float64 {
// 	return math.Sqrt(math.Pow(a.X-b.X, 2) + math.Pow(a.Y-b.Y, 2))
// }
//
// func centroid(cluster []Point) Point {
// 	var x, y float64
// 	for _, point := range cluster {
// 		x += point.X
// 		y += point.Y
// 	}
// 	return Point{x / float64(len(cluster)), y / float64(len(cluster))}
// }
//
//
//
//
//
//
//
//
//
//
//
//
