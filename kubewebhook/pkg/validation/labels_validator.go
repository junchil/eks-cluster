package validation

import (
	"fmt"

	"github.com/sirupsen/logrus"
	corev1 "k8s.io/api/core/v1"
)

// labelsValidator is a container for validating the labels of pods
type labelsValidator struct {
	Logger logrus.FieldLogger
}

// nameValidator implements the podValidator interface
var _ podValidator = (*labelsValidator)(nil)

// Name returns the name of nameValidator
func (n labelsValidator) Name() string {
	return "labels_validator"
}

// Validate inspects the labels of a given pod and returns validation.
// The returned validation is only valid if the pod labels contain managedby: steve
func (n labelsValidator) Validate(pod *corev1.Pod) (validation, error) {
	const (
		validateLabel      = "managedby"
		validateLabelValue = "steve"
	)
	if _, ok := pod.Labels[validateLabel]; !ok {
		v := validation{
			Valid:  false,
			Reason: fmt.Sprintf("pod labels does not contain managedby label"),
		}
		return v, nil
	}

	if val, ok := pod.Labels[validateLabel]; ok {
		if val != validateLabelValue {
			v := validation{
				Valid:  false,
				Reason: fmt.Sprintf("pod managedby label's value is not equal to steve"),
			}
			return v, nil
		}
	}

	return validation{Valid: true, Reason: "valid lables"}, nil
}
