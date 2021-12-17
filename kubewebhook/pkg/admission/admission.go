package admission

import (
	"github.com/sirupsen/logrus"
	admissionv1 "k8s.io/api/admission/v1"
)

// Admitter is a container for admission business
type Admitter struct {
	Logger  *logrus.Entry
	Request *admissionv1.AdmissionRequest
}
