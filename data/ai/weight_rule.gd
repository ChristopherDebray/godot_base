## Calculates a weight for a given item and context. Context is a Dictionary you define (distance, los, status, etc.).
class_name WeightRule
extends Resource

func weight_for(item: Variant, context: Dictionary) -> float:
	# Default implementation: neutral (use caller fallback).
	return -1.0  # negative means "no opinion / fallback"
