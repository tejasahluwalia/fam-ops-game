# Starter Kit for a Top-Down Action Adventure Game


https://github.com/user-attachments/assets/ea57e4ae-660c-4feb-a5fc-0f1929f3c775


Work-in-progress of a action adventure starter kit for Godot 4.
**NOTE:** Developed in and compatible with **Godot 4.3**. It looks like that `MeshLibrary` is breaking compatibility with 4.2. 

Credits and thank you to:
- @kaylousberg for the FREE [Kaykit Prototype Bits](https://kaylousberg.itch.io/prototype-bits) as a base for the 3D Assets;
- [Dialogic2](https://github.com/dialogic-godot/dialogic)'s contributors for their amazing dialogue manager, used for all my dialogues and cutscenes;
- [Beehave](https://github.com/bitbrain/beehave)'s contributors for their amazing decision tree add-on, used for my ennemies;
- @kenney for his [Input Prompt](https://kenney.nl/assets/input-prompts) assets and [Interface Sound](https://kenney.nl/assets/interface-sounds) assets;
- [kidscancode tutorials](https://kidscancode.org/godot_recipes/3.x/ui/debug_overlay/index.html) for the building block of a DebugLayer

Follow me on Twitter/X to get regular updates about the development and coming features: 

[![Twitter URL](https://img.shields.io/twitter/url/https/twitter.com/nodragem.svg?style=social&label=%20%40nodragem)](https://twitter.com/nodragem)

# Loading the project for the first time:

1) Clone or download this repository in a folder
2) Open the project in Godot (there will be a lot of errors, because of missing add-ons)
3) Click on AssetLib, search for Beehave and install it
4) Download [Dialogic2 from here](https://github.com/dialogic-godot/dialogic/archive/refs/tags/2.0-alpha-14.zip)
5) Unzip, find the `dialogic` folder (in the folder `addons`) and paste it in the `res://addons` folder of the Godot project
6) Go in `Project/Project Settings`, in the tab `Plugins`, activate both Beehave and Dialogic
7) (Optional) For your peace of mind, you might want to reload the project
8) Run the Game! 

# Features:
## Gridmap Powered
Discover how I use Gridmapd and NavMeshRegion together:

https://github.com/user-attachments/assets/72e7dddc-e480-4b0c-b6d9-caa011d9947b

And how I organised my levels:
![gridmap-layers](https://github.com/user-attachments/assets/e1596bbe-f00d-4722-9cf0-400297c0e7d5)

## Ennemy with Behaviour Tree based AI
Discover how I use Beehave to implement a simple chase and hit behaviour:

https://github.com/user-attachments/assets/14d90d69-e94f-4b3d-b3a4-223a13dd03ae

## Character Controller
Support Gamepad or Keyboard, select between 4 controller schemes:

https://github.com/user-attachments/assets/d5aec914-9959-4808-b82f-dbed37f242ca

Camera follows Main Character and can be rotated with RT/LT.

Animation System based on a Blend Tree and Fully modelled and rigged character:

https://github.com/user-attachments/assets/0c944c9c-6f03-4099-b1b3-617800df9002

Logic based on a State Machine (inspired from GDQuest tutorials):
![image](https://github.com/user-attachments/assets/9313827f-44a9-4333-9402-b8ebed96db3f)

## Switch system
Short switches, long switches, area switches can control enemy spawners and doors through a switch hub:

https://github.com/user-attachments/assets/fd78d5af-78e4-4872-a28d-e0b329871022

Here an example to close the doors and start spawning ennemies when a player walks in a room:
![switches1](https://github.com/user-attachments/assets/57bad863-7e54-4777-a4a7-3add3978a566)

## Cutscene and Game Events
Discover how I create dialogs that react to the player interactions:

https://github.com/user-attachments/assets/e4fbace3-23a8-45d4-ad4e-3f641173eff6

Discover how I made cutscenes using the Animation Player and Dialogic:

https://github.com/user-attachments/assets/d39b80bf-0cbf-4142-bdc6-6254d1607445

## Advanced Import methods
Discover how my GLTF files become destructible objects on drag-and-drop:

https://github.com/user-attachments/assets/5faa3ca5-2bdd-4ee7-b710-a01933d6d776

## Game Feel Included
Destructible elements, Hit feedback, Particles, Recoil animation (more to come):
![killed-animation-in-game](https://github.com/user-attachments/assets/2e20c55c-2a87-4d6a-b8b1-053973a31279)

Discover an example of explosion VFX:
![demo-particles](https://github.com/user-attachments/assets/ff048914-30fb-4214-bc05-d79c89ba0391)

## Always wanted to replicate the Inifinite Inertia from Godot 3?
Collision layers are set up to reproduce the `infinite_inertia` property which was dropped in Godot 4:

https://github.com/user-attachments/assets/99b09b1a-758d-4a40-8d3a-a13b3b70f910

## Debug Layer and Stats
Work-in-progress, display properties when pressing L:
![demo-debugger](https://github.com/user-attachments/assets/866ac4e1-336a-4f91-92af-5d7c02f6be01)


# Controls
Press `start` button of your gamepad to open a menu and select between 3 controller schemes:
- One Stick Controller (move with Left Stick, aim with Left Trigger, shoot with B)
- Two Stick Controller (move with Left Stick, aim with Right Stick, shoot with Left Trigger)
- Two Stick Auto-Shoot Controller (move with Left Stick, aim and shoot with Right Stick, Move Camera with RT/LT)

If no Gamepad only the One Stick Controller works at the moment:
- Move with `Arrow` keys
- Jump with `Space` key
- Aim with `Q` key
- Shoot with `W` key (you can only shoot if you are aiming)

Debug Layer which can be toggled with `L` key
