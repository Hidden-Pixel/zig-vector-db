package kmeans 

import (
	"testing"
)


func TestCentroid(t *testing.T) {
	tests := []struct {
		name     string
		cluster  []Point
		expected Point
	}{
		{
			name: "test 1",
			cluster: []Point{
				{X: 1, Y: 1},
				{X: 2, Y: 2},
				{X: 3, Y: 3},
			},
			expected: Point{X: 2, Y: 2},
		},
		{
			name: "test 2",
			cluster: []Point{
				{X: -1, Y: -2},
				{X: 0, Y: 0},
				{X: 1, Y: 2},
			},
			expected: Point{X: 0, Y: 0},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if result := centroid(test.cluster); result != test.expected {
				t.Errorf("centroid() = %v, want %v", result, test.expected)
			}
		})
	}
}
