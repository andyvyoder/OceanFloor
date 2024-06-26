# OceanFloor


## Problem Description

Create a RealityKit iOS app that detects floors in your physical environment and renders an ocean on top of the floor with moving water/waves. Following are some of specs on the ocean:

- Ocean should span detected **floors only**.
- Ocean should **grow with the size of the detected floor** i.e., if the user continues to move the camera around to detect more of the floor, then ocean should expand to cover newly detected floor
- **Detect an item** of your choice in the scene(e.g chair, bottle, sofa etc) to occlude the ocean floor i.e when the item is between the phone and the ocean floor, the item should appear on top of the ocean instead of behind it.
- **Build UI controls** to change the **color** of the ocean and **height** of the ocean waves
- Please upload your code into your github repo and give us access to your project by **April-7, 12PM**

Note: Enabling of **SceneUnderstanding.Options.Occlusion** property in RealityKit is prohibited for implementing occlusion.



## App Usage

This application renders an undulating mesh on the floor to simulate a wave pattern. 

There is a gear icon in the corner, pressing this will open a panel on the left where you can adjust the wave height and color.


## Video

Link to a video of the app running:

https://drive.google.com/file/d/1HQcyYyTCewsYCfo-QI9gh7aY-1lLCzOB/view?usp=drive_link


## Devices Tested

Tested on an iPad Pro (11-inch 4th gen) running iOS 17.4.1


## Code Provenance:

This project uses code from some Apple sample projects. Classes that came from Apple sample code are commented as coming from Apple.

A couple of files are untouched from the original Apple samples and those files retain their original Apple license comment at the top.


## Approach:

- OceanView receives Anchor adds/updates/removes
- These are passed off to MeshAnchorTracker which maintains AnchorEntities based on anchor updates.
- MeshAnchorTracker alters WaveSystem when the underlaying ARMeshAnchors update
- WaveSystem handles processing the meshes associated with the ARMeshAnchors into meshes that represent only the floor
    - Each AnchorEntity has a WaveComponent added to it and when the mesh is ready it will have a ModelComponent as well. Essentially each AnchorEntity is a mesh that is part of the overall wave.
    - WaveSystem makes use of WaveMeshProcessingTracker. It keeps one per  AnchorEntity which lets it track and process meshes for each wave’s mesh separately.
    - WaveMeshProcessingTracker ensures that mesh processing happens correctly even if new meshes need to be processed when there is one already in progress.
    - The wave mesh is generated by using the classification of each face to produce a new mesh with a subset of the faces of the original (see ARMeshGeometry-Extentions).
- There is a custom surface shader and geometry modifier.
    - The surface shader is passed parameters for the wave’s color a texture to blend with the custom color
    - The geometry modifier adds the undulating wave motion and is passed a parameter to control the wave height


## Unfinished work / Places for improvement: 

- My approach to having a specific object occlude the wave did not pan out. I attempted to recognize a jar of pickle using ARKit’s Object Detection, but I didn’t find its positioning to be accurate enough to position a tight fitting occlusion model (in my case a cylinder because it was a jar).
- WaveSystem could have simply been a class an not a system. Having it be a system lead to unsightly things like making a static instance reference for OceanView and WaveSystem.
- The way settings are accessed is not ideal. WaveSystem needs to access the settings, and it currently does this by getting it from OceanView. But WaveSystem shouldn't know about OceanView at all.