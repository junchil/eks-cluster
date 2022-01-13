/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"
	"reflect"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	appstevejcliuiov1alpha1 "github.com/junchil/eks-cluster/golang-app-operator/api/v1alpha1"
)

// GolangappoperatorReconciler reconciles a Golangappoperator object
type GolangappoperatorReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=app.stevejcliu.io.stevejcliu.com,resources=golangappoperators,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=app.stevejcliu.io.stevejcliu.com,resources=golangappoperators/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=app.stevejcliu.io.stevejcliu.com,resources=golangappoperators/finalizers,verbs=update

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the Golangappoperator object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.10.0/pkg/reconcile
func (r *GolangappoperatorReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := log.FromContext(ctx)

	// Fetch the Golangappoperator instance
	golangappoperatored := &appstevejcliuiov1alpha1.Golangappoperator{}
	err := r.Get(ctx, req.NamespacedName, golangappoperatored)
	if err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			// Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
			// Return and don't requeue
			log.Info("golangappoperatored resource not found. Ignoring since object must be deleted")
			return ctrl.Result{}, nil
		}
		// Error reading the object - requeue the request.
		log.Error(err, "Failed to get golangappoperatored")
		return ctrl.Result{}, err
	}

	// Check if the deployment already exists, if not create a new one
	found := &appsv1.Deployment{}
	err = r.Get(ctx, types.NamespacedName{Name: golangappoperatored.Name, Namespace: golangappoperatored.Namespace}, found)
	if err != nil && errors.IsNotFound(err) {
		// Define a new deployment
		dep := r.deploymentForGolangappoperatored(golangappoperatored)
		log.Info("Creating a new Deployment", "Deployment.Namespace", dep.Namespace, "Deployment.Name", dep.Name)
		err = r.Create(ctx, dep)
		if err != nil {
			log.Error(err, "Failed to create new Deployment", "Deployment.Namespace", dep.Namespace, "Deployment.Name", dep.Name)
			return ctrl.Result{}, err
		}
		// Deployment created successfully - return and requeue
		return ctrl.Result{Requeue: true}, nil
	} else if err != nil {
		log.Error(err, "Failed to get Deployment")
		return ctrl.Result{}, err
	}

	// Ensure the deployment size is the same as the spec
	size := golangappoperatored.Spec.Size
	if *found.Spec.Replicas != size {
		found.Spec.Replicas = &size
		err = r.Update(ctx, found)
		if err != nil {
			log.Error(err, "Failed to update Deployment", "Deployment.Namespace", found.Namespace, "Deployment.Name", found.Name)
			return ctrl.Result{}, err
		}
		// Ask to requeue after 1 minute in order to give enough time for the
		// pods be created on the cluster side and the operand be able
		// to do the next update step accurately.
		return ctrl.Result{RequeueAfter: time.Minute}, nil
	}

	// Update the golangappoperatored status with the pod names
	// List the pods for this golangappoperatored's deployment
	podList := &corev1.PodList{}
	listOpts := []client.ListOption{
		client.InNamespace(golangappoperatored.Namespace),
		client.MatchingLabels(labelsForGolangappoperator(golangappoperatored.Name)),
	}
	if err = r.List(ctx, podList, listOpts...); err != nil {
		log.Error(err, "Failed to list pods", "golangappoperatored.Namespace", golangappoperatored.Namespace, "golangappoperatored.Name", golangappoperatored.Name)
		return ctrl.Result{}, err
	}
	podNames := getPodNames(podList.Items)

	// Update status.Nodes if needed
	if !reflect.DeepEqual(podNames, golangappoperatored.Status.Nodes) {
		golangappoperatored.Status.Nodes = podNames
		err := r.Status().Update(ctx, golangappoperatored)
		if err != nil {
			log.Error(err, "Failed to update golangappoperatored status")
			return ctrl.Result{}, err
		}
	}

	return ctrl.Result{}, nil
}

// deploymentForGolangappoperatored returns a golangappoperatored Deployment object
func (r *GolangappoperatorReconciler) deploymentForGolangappoperatored(m *appstevejcliuiov1alpha1.Golangappoperator) *appsv1.Deployment {
	ls := labelsForGolangappoperator(m.Name)
	replicas := m.Spec.Size

	dep := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      m.Name,
			Namespace: m.Namespace,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: ls,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: ls,
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{{
						Image: "675617749633.dkr.ecr.ap-southeast-2.amazonaws.com/eks-cluster/golang-app:v1",
						Name:  "golangappoperator",
						Ports: []corev1.ContainerPort{{
							ContainerPort: 8081,
							Name:          "golangappoperatored",
						}},
					}},
				},
			},
		},
	}
	// Set golangappoperatored instance as the owner and controller
	ctrl.SetControllerReference(m, dep, r.Scheme)
	return dep
}

func labelsForGolangappoperator(name string) map[string]string {
	return map[string]string{"app": "golangappoperatored", "golangappoperatored_cr": name}
}

// getPodNames returns the pod names of the array of pods passed in
func getPodNames(pods []corev1.Pod) []string {
	var podNames []string
	for _, pod := range pods {
		podNames = append(podNames, pod.Name)
	}
	return podNames
}

// SetupWithManager sets up the controller with the Manager.
func (r *GolangappoperatorReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&appstevejcliuiov1alpha1.Golangappoperator{}).
		Complete(r)
}
