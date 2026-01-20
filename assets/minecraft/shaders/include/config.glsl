//
//  -=- Faithless Config File -=-
//  Everything here is either non functional or experimental. '//X' means non-functional.
//
//  To toggle a feature, set True to False. 
//	If the line has a numeric value, 0 will disable it
//	If the line has a decimal, it accepts more precise values.
//	
// ============================================================================
//  WAVING ANIMATIONS
// ============================================================================

		#define Waving_Features true 		//Toggle-All

		#define Waving_Grass 1.0 			//(Grass, Flowers, Crops...)
		#define Waving_Foliage 1.0 			//(Leaves, Vines, Bushes...)
		#define Waving_Objects 1.0 			//(Chains, Lanterns, Webs...)
		#define Waving_Water 1.0			//(Water, Seagrass, Lilypads...)
		#define Waving_Lava 0.5
		#define Waving_Fire 1.0

// ============================================================================
//  Interface and GUI 
// ============================================================================
		
		#define Alt_Hotbar 1				//Alt Hotbar Layouts                        		//X
		#define Hitboxes 1					//Alt Block Selection Outlines              		//X
				
		#define Menu_BG 1					//Alt Menu Dirt Backgrounds							//X
		
		#define Minimap true 				//Displays a minimap of rendered chunks             //X
		
// You can adjust the RGBA values to your preferences. (Ignore the * (0.00392))
// --- FLAT UI BACKGROUNDS ---

		const vec4 Reload_Screen[4] = vec4[4](
			vec4(127, 51, 26, 200) * (0.00392), vec4(76, 26, 26, 200) * (0.00392),
			vec4( 76, 26, 26, 200) * (0.00392), vec4( 0,  0,  0, 200) * (0.00392)
		);
		
		const vec4 Inventory[4] = vec4[4](
			vec4(0, 0, 0, 0) * (0.00392), vec4(0, 0, 0, 255) * (0.00392),
			vec4(0, 0, 0, 0) * (0.00392), vec4(0, 0, 0, 255) * (0.00392)
		);
		
		const vec4 Debug_Menu[4] = vec4[4](
			vec4(0, 0, 0, 220) * (0.00392), vec4(0, 0, 0, 220) * (0.00392),
			vec4(0, 0, 0, 190) * (0.00392), vec4(0, 0, 0, 190) * (0.00392)
		);
		
		const vec4 Chat_Messages[4] = vec4[4](
			vec4(0, 0, 0, 255) * (0.00392), vec4(0, 0, 0, 0) * (0.00392),
			vec4(0, 0, 0, 255) * (0.00392), vec4(0, 0, 0, 0) * (0.00392)
		);
		
// --- UI TEXT COLORS ---
												//  Text 								  Shadow
		const vec4 splash[2] = 			vec4[](vec4(255, 255,   0, 255) * (0.00392), vec4(200, 120, 0, 255) * (0.00392));
		const vec4 buttons[2] =			vec4[](vec4(255, 255, 255, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392)); 
		const vec4 disabledButtons[2] = vec4[](vec4(255,   0,   0, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		const vec4 worldInfo[2] = 		vec4[](vec4(190, 248, 248, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		const vec4 cmd_n_packInfo[2] =	vec4[](vec4(190, 248, 248, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		
		const vec4 inventory[1] = 		vec4[](vec4(  0,   0,   0, 255) * (0.00392));
		const vec4 experience[2] = 		vec4[](vec4(  0, 255,   0, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		const vec4 beacon[2] = 			vec4[](vec4(255, 255, 255, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		const vec4 anvilExp[2] =		vec4[](vec4(  0, 255,   0, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		const vec4 anvilExpLow[2] =		vec4[](vec4(255,   0,   0, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		const vec4 tooltip[2] = 		vec4[](vec4(255, 255, 255, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		
		const vec4 messages[2] =		vec4[](vec4(255, 255, 255, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392)); 
		const vec4 cmdFill[2] = 		vec4[](vec4(182,   0, 255, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		const vec4 cmdSelect[2] = 		vec4[](vec4(182, 255,   0, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		const vec4 cmdError[2] = 		vec4[](vec4(255,   0,   0, 255) * (0.00392), vec4(0, 0, 0, 255) * (0.00392));
		
		const vec4 debugMenu[13] = vec4[](
			vec4(198,  79,  81, 255) * (0.00392),	//0 Title
			vec4(129, 177, 170, 255) * (0.00392),	//1 Text
			vec4(255, 255, 255, 255) * (0.00392),	//2 Numbers
			vec4(129, 128, 132, 255) * (0.00392),	//3 Fract Symbols
			vec4(255, 192,  76, 255) * (0.00392),	//4 FPS 
			vec4(206,  37,  45, 255) * (0.00392),	//5 X Axis
			vec4( 84, 204,  51, 255) * (0.00392),	//6 Y Axis
			vec4(  0, 182, 255, 255) * (0.00392),	//7 Z Axis
			vec4(151, 122, 235, 255) * (0.00392),	//8 World Info
			vec4(  0, 186, 210, 255) * (0.00392),	//9 Hardware Info
			vec4(187,  92,  55, 255) * (0.00392),	//10 Block Data
			vec4( 68,  43,  23, 255) * (0.00392),	//11 Block Data Spaces
			vec4(188,  89,  64, 255) * (0.00392)	//12 Block Tags
		);
		
// ============================================================================
//  Skins 
// ============================================================================

		#define Player_Skin_Features true	// Toggle-All skin features for every player
		
      //-=- ALL SKINS TOGGLE -=-			// -=- PERSONAL SKIN -=-								|	-=- DESCRIPTION -=-
		#define Player_Blink_Face true		// toggle  r1.. =On										|	Blinking eyes face
		#define Player_Transparency true	// scale   r.1. =strips; r.2. =stripInv; 				|	Allow the entire skin to support transparency
		#define Player_Emissives true		// scale   r..1 =strips; r..2 =stripInv; r..3 =all		|	Define which areas of your skin glow 
 		#define Player_Hurt_Face true		// toggle  g1.. =On										|	Face when taking damage
		#define Player_Hurt_Mask true		// scale   g.1. =strips; g.2. =stripInv;	g.3. =all	|	Define which areas of your skin are tinted/masked when hurt
		#define Player_Reflection true		// scale   g..1 =strips; g..2 =stripInv; g..3 =all 		|	Define which areas of your skin are reflective					//X
		#define Player_Squint_Face true		// toggle  b1.. =On										|	Eyes Squint when adjusting to darkness or brigtness
		#define Player_Breathing true		// toggle  b.1. =On										|	Improved idle stance  											//X
		#define Player_Cape true 			// toggle  b..1 =On										|	4p & 3p arms have 8x12 and 10x12 capes respectively
		#define Player_Pixel_Anim true		// toggle  a1.. =interpolate							|	Define which colors on your skin interpolate (*)				//X
											// scale   a.1. =speed 									|	(*) Define how fast colors on your skin interpolate
		#define Player_Pixel_Mask true		// scale   g..1 =strips; g..2 =stripInv; g..3 =all		|	Define which areas of your skin have special effects			//X
		#define Player_Hurt_Color true		// mask    alpha = 220									|	Define the tint color when taking damage.
		
// ============================================================================
//  Fun
// ============================================================================

		#define Fresh_Animations true		//Fresh Animations at Home							//X
		#define TFAILA true 				//WAILA at home										//X
		#define Emissives true  			//Textures appear to glow, but don't emit light.
		#define Displacement true 			//Foliage and objects will be crushed under you
		
		#define Windowlogging true 			//Glass Panes & Iron Bars connect to slabs and stairs
		#define Fencelogging true 			//Fences & Walls connect to slabs and stairs
		#define Snowlogging true 			//Snow and Moss will connect to fences and panes
		#define Dynamic_Slopes true 		//Dynamic Snow and Moss
		
		#define Layered_Clouds true 		//Clouds will vary on Y level
		#define Puffy_Clouds true 			//Clouds will look puffier and brighter
		#define Sunken_Clouds true 			//Clouds will sink depending on weather and time
		
		#define Big_Trees true 				//Gives 2x2 trees a unique texture
		#define Block_Animations true		//Jukebox Disc, Beacon, and Creaking Heart
		#define Ender_Chest true 			//Ender Chest End Portal Effect
		#define Portal_Fog true 			//Gives the Nether portal ambient fog
		#define Dimensional_Foliage true 	//Gives the Nether and End some ambient foliage
		
		#define Billboard_Items true		//2D Items like Beta Minecraft                      //X
		#define Billboard_Blocks true 		//Cross models become 2d sprites that follow you    //X
		
		#define Destroy_Depth 1.0			//3D Breaking Animation
		#define Cubic_Particles true		//3D Particles
		
		#define Render_Player True 			//Render the whole player in first person           //X
		
		#define Explosion_Power 1.0 		//Explosions cause the screen to shake              //X
		#define CelShading 1.0				//Cel-Shading intensity                             //X
  		#define Orthographic false			//Removes Perspective Depth							//X
  		#define Colorblindness 0			//0 = None, 1 = Protan, 2 = Deutan, 3 = Tritan, 4 = Mono
		
		#define Fog_Distance 0.3 	 		//Fog Density
  		#define Chunk_Loading 1				//0 = Vanilla, 1 = Rising Chunks, 2 = Block Fade

// ============================================================================
//  Lighting and Environmental Effects
// ============================================================================

		#define Volumetric_Clouds true		// Volumetric Clouds								//X
		#define Volumetric_Fog true			// Volumetric Fog                   				//X
		#define Volumetric_Grass true		// Volumetric Grass                 				//X
		#define Shadows true				// Shadows                          				//X
		#define Reflections true			// Reflections                      				//X
		#define Motion_Blur 1.0				// Motion Blur                      				//X
		#define DOF 1.0						// Depth of Field                   				//X
		#define Exposure 1.0				// Light Exposure                   				//X
		#define Bloom true					// Bloom effect                     				//X
		#define Sun_Moon_Angle 1.0			// Sun/Moon Angle                   				//X
		#define Skybox true					// Custom Overworld Skybox          				//X
		#define End_Skybox true				// Custom End skybox                				//X

// ============================================================================