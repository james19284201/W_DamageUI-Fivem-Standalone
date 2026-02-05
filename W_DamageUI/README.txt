========================================
Wothless Damage UI
========================================

DISCORD SUPPORT
----------------------------------------
Join the Discord for support, updates, and future releases:
https://discord.gg/sVPPQXzmh4

CREDITS
----------------------------------------
This resource is provided free to use.
Do NOT reupload as your own work.
Do NOT sell this resource.

NOTES
----------------------------------------
• This script is designed to be public-friendly and lightweight.
• All logic is client-side safe and optimized.
• Built to avoid common FiveM UI bugs (ghost mouse, stuck focus, forced display).

DOWNLOAD & INSTALLATION
----------------------------------------
1. Download the resource folder.
2. Place the folder into your server’s `resources` directory.
3. Ensure the resource in your `server.cfg`:

   ensure Wothless-DamageUI

4. Restart your server.

COMMANDS
----------------------------------------
/cdamageui        Opens the Damage UI settings menu

REQUIREMENTS
----------------------------------------
• FiveM server
• Standalone (NO framework required)
• Does NOT require ESX / QBCore / vRP


BASIC USAGE
----------------------------------------
• Damage UI appears when the player is injured (or always, depending on settings)
• Open Damage UI settings with:
  
  /cdamageui

• Go to a medical location and press:
  
  [E] Receive Medical Treatment

• Click individual body parts to heal them instantly
• UI handles health, effects, and movement automatically


CONFIGURATION (IMPORTANT)
----------------------------------------
Healing locations are defined at the TOP of the client file for easy editing.

Example:
HealingSpots = {
    vector3(x, y, z),
    vector3(x, y, z)
}

You can add as many locations as you want.


WHAT THIS SCRIPT DOES
----------------------------------------
• Tracks individual body part injuries:
  - Head
  - Torso
  - Left Arm
  - Right Arm
  - Left Leg
  - Right Leg

• Applies realistic effects:
  - Limping when legs are injured
  - Dizzy / blackout effects for head injuries
  - Ragdoll chance based on leg damage

• Medical system:
  - Floor-based medical interaction
  - Click-to-heal body parts
  - Timed healing progress
  - Restores GTA health when fully healed
  - Clears ALL lingering effects correctly

• Fully custom Damage UI:
  - Moveable on screen
  - Color customizable
  - Display modes:
      • Always
      • Only when injured
  - Smooth fade in / fade out
  - No ghost UI or stuck mouse issues

• NUI Safety:
  - Proper focus handling
  - Menus never lock controls
  - Cancel buttons correctly release mouse
  - No auto-closing bugs