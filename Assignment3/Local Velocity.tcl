package require vtk
package require vtkinteraction

#
# This example reads a volume dataset, extracts an isosurface that
# represents the skin and displays it.
#

# Create the renderer, the render window, and the interactor. The renderer
# draws into the render window, the interactor enables mouse- and
# keyboard-based interaction with the scene.
#
vtkRenderer aRenderer
vtkRenderWindow renWin
  renWin AddRenderer aRenderer
vtkRenderWindowInteractor iren
  iren SetRenderWindow renWin

# The following reader is used to read a series of 2D slices (images)
# that compose the volume. The slice dimensions are set, and the
# pixel spacing. The data Endianness must also be specified. The reader
# usese the FilePrefix in combination with the slice number to construct
# filenames using the format FilePrefix.%d. (In this case the FilePrefix
# is the root name of the file: quarter.)
vtkStructuredPointsReader reader
	reader SetFileName "velocity.dat"
	reader Update
	
 vtkConeSource cone 
  cone SetResolution 10 
  cone SetHeight 0.75
  cone SetRadius 0.15
  
vtkPointSource seeds 
	seeds SetRadius 1.0 
	seeds SetCenter 9 9 5 
	seeds SetNumberOfPoints 100 
	
vtkRungeKutta4 integ

vtkStreamTracer streamer 
	streamer SetInputConnection [reader GetOutputPort] 
	streamer SetSourceConnection [seeds GetOutputPort] 
	streamer SetMaximumPropagation 100 
	streamer SetInitialIntegrationStep 0.1 
	streamer SetIntegrationDirectionToBoth
	streamer SetIntegrator integ
	
vtkTubeFilter tubes
	tubes SetInputConnection [streamer GetOutputPort]
	tubes SetRadius 0.05
	tubes SetNumberOfSides 6
	tubes SetVaryRadiusToVaryRadiusByScalar

# An isosurface, or contour value of 500 is known to correspond to the
# skin of the patient. Once generated, a vtkPolyDataNormals filter is
# is used to create normals for smooth surface shading during rendering.
# The triangle stripper is used to create triangle strips from the
# isosurface these render much faster on may systems.
  
vtkLookupTable lut
lut SetTableRange 0 1
	lut SetHueRange 0.667 0 
	lut SetSaturationRange 1 1
	lut SetValueRange 1 1
	lut SetNumberOfColors 256
	lut Build
  
vtkPolyDataMapper tubeMapper 
	tubeMapper SetInputConnection [tubes GetOutputPort] 
	tubeMapper SetLookupTable lut 
	tubeMapper ScalarVisibilityOn
	eval tubeMapper SetScalarRange [[reader GetOutput] GetScalarRange] 
vtkActor tubes1
  tubes1 SetMapper tubeMapper

# An outline provides context around the data.
#

vtkScalarBarActor scalarBar 
	scalarBar SetLookupTable [tubeMapper GetLookupTable]
	scalarBar SetTitle "Temperature"
	[scalarBar GetPositionCoordinate] SetCoordinateSystemToNormalizedViewport
	[scalarBar GetPositionCoordinate] SetValue 0.006 0.1
	scalarBar SetWidth 0.12
	scalarBar SetHeight 0.9
	
	
vtkOutlineFilter outlineData
  outlineData SetInputConnection [reader GetOutputPort]
vtkPolyDataMapper mapOutline
  mapOutline SetInputConnection [outlineData GetOutputPort]
vtkActor outline
  outline SetMapper mapOutline
  [outline GetProperty] SetColor 0 0 0

# It is convenient to create an initial view of the data. The FocalPoint
# and Position form a vector direction. Later on (ResetCamera() method)
# this vector is used to position the camera to look at the data in
# this direction.
vtkCamera aCamera
  aCamera ComputeViewPlaneNormal

 vtkAxes axes
  axes SetOrigin 0 0 0
 vtkTubeFilter axesTubes
	axesTubes SetInputConnection [axes GetOutputPort]
	axesTubes SetRadius 0.1
	axesTubes SetNumberOfSides 6
	
	vtkPolyDataMapper axesMapper
		axesMapper SetInputConnection [axesTubes GetOutputPort]
	vtkActor axesActor
		axesActor SetMapper axesMapper
		axesActor SetScale 2 2 2


# Actors are added to the renderer. An initial camera view is created.
# The Dolly() method moves the camera towards the FocalPoint,
# thereby enlarging the image.
aRenderer AddActor outline
aRenderer AddActor tubes1
#aRenderer AddActor skin
aRenderer AddActor scalarBar
aRenderer AddActor axesActor
aRenderer SetActiveCamera aCamera
aRenderer ResetCamera
aCamera Dolly 1.5

# Set a background color for the renderer and set the size of the
# render window (expressed in pixels).
aRenderer SetBackground 1 1 1
renWin SetSize 640 480

# Note that when camera movement occurs (as it does in the Dolly()
#method),the clipping planes often need adjusting. Clipping planes
#consist of two planes: near and far along the view direction. The
# near plane clips out objects in front of the plane the far plane
# clips out objects behind the plane. This way only what is drawn
# between the planes is actually rendered.
aRenderer ResetCameraClippingRange

iren Initialize

vtkWindowToImageFilter w2i
	w2i SetInput renWin
#vtkJPEGWriter writer
#	writer SetInputConnection [w2i GetOutputPort]
#	writer SetFileName "temperature_iso_95s.jpg"
#	writer Write
	
iren Start