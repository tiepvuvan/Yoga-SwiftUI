// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.
extension StyleAccess {
    @inline(__always) borrowing func processedDimension(_ axis: YogaFlexDirection) -> YogaValue {
        let maximum = maximum(axis)
        if maximum.isDefined {
            if maximum == minimum(axis) { return maximum }
        }
        return dimension(axis)
    }

    @inline(__always) borrowing func hasDefiniteLength(_ axis: YogaFlexDirection, _ reference: Float) -> Bool {
        processedDimension(axis).resolve(reference) >= 0
    }

    @inline(__always) borrowing func resolvedDimension(_ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float, _ width: Float) -> Float {
        resolved(processedDimension(axis), axis, direction, reference, width)
    }

    @inline(__always) borrowing func boundMinMax(_ value: Float, _ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float, _ width: Float) -> Float {
        let minValue = resolved(minimum(axis), axis, direction, reference, width)
        let maxValue = resolved(maximum(axis), axis, direction, reference, width)
        if maxValue >= 0 && value > maxValue { return maxValue }
        if minValue >= 0 && value < minValue { return minValue }
        return value
    }

    @inline(__always) borrowing func bound(_ value: Float, _ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float, _ width: Float) -> Float {
        maxDefined(boundMinMax(value, axis, direction, reference, width), paddingBorder(axis, direction, width))
    }

}
