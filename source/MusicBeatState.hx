package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		var sprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image('cursor'));
		FlxG.mouse.load(sprite.pixels);

		CoolUtil.setFPSCap(SaveData.framerate);

		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new CustomFadeTransition(0.7, true));

		FlxTransitionableState.skipNextTransOut = false;

		super.create();
	}

	override function update(elapsed:Float)
	{
		var nextStep:Int = updateCurStep();

		if (nextStep >= 0)
		{
			if (nextStep > curStep)
			{
				for (i in curStep...nextStep)
				{
					curStep++;
					updateBeat();
					stepHit();
				}
			}
			else if (nextStep < curStep)
			{
				// Song reset?
				curStep = nextStep;
				updateBeat();
				stepHit();
			}
		}

		if (CoolUtil.getFPSCap() != SaveData.framerate)
			CoolUtil.setFPSCap(SaveData.framerate);

		// let's improve performance of this a tad
		if (FlxG.autoPause != SaveData.autoPause)
			FlxG.autoPause = SaveData.autoPause;

		super.update(elapsed);
	}

	public static function switchState(nextState:FlxState)
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.resetState();
				};
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	private function updateBeat():Void
	{
		lastBeat = curBeat;
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}
}
#if mobile
import mobile.flixel.FlxHitbox;
import mobile.flixel.FlxVirtualPad;
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end
	#if mobile	var hitbox:FlxHitbox;

	var virtualPad:FlxVirtualPad;

	var trackedInputsHitbox:Array<FlxActionInput> = [];

	var trackedInputsVirtualPad:Array<FlxActionInput> = [];

	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode, ?visible = true):Void

	{

		if (virtualPad != null)

			removeVirtualPad();

		virtualPad = new FlxVirtualPad(DPad, Action);

		virtualPad.visible = visible;

		add(virtualPad);

		controls.setVirtualPadUI(virtualPad, DPad, Action);

		trackedInputsVirtualPad = controls.trackedInputsUI;

		controls.trackedInputsUI = [];

	}

	public function addVirtualPadCamera(DefaultDrawTarget:Bool = true):Void

	{

		if (virtualPad != null)

		{

			var camControls:FlxCamera = new FlxCamera();

			FlxG.cameras.add(camControls, DefaultDrawTarget);

			camControls.bgColor.alpha = 0;

			virtualPad.cameras = [camControls];

		}

	}

	public function removeVirtualPad():Void

	{

		if (trackedInputsVirtualPad.length > 0)

			controls.removeVirtualControlsInput(trackedInputsVirtualPad);

		if (virtualPad != null)

			remove(virtualPad);

	}

	public function addHitbox(?visible = true):Void

	{

		if (hitbox != null)

			removeHitbox();

		hitbox = new FlxHitbox();

		hitbox.visible = visible;

		add(hitbox);

		controls.setHitBox(hitbox);

		trackedInputsHitbox = controls.trackedInputsNOTES;

		controls.trackedInputsNOTES = [];

	}

	public function addHitboxCamera(DefaultDrawTarget:Bool = true):Void

	{

		if (hitbox != null)

		{

			var camControls:FlxCamera = new FlxCamera();

			FlxG.cameras.add(camControls, DefaultDrawTarget);

			camControls.bgColor.alpha = 0;

			hitbox.cameras = [camControls];

		}

	}

	public function removeHitbox():Void

	{

		if (trackedInputsHitbox.length > 0)

			controls.removeVirtualControlsInput(trackedInputsHitbox);

		if (hitbox != null)

			remove(hitbox);

	}

	#end

	override function destroy()

	{

		#if mobile

		if (trackedInputsHitbox.length > 0)

			controls.removeVirtualControlsInput(trackedInputsHitbox);

		if (trackedInputsVirtualPad.length > 0)

			controls.removeVirtualControlsInput(trackedInputsVirtualPad);

		#end

		super.destroy();

		#if mobile

		if (virtualPad != null)

			virtualPad = FlxDestroyUtil.destroy(virtualPad);

		if (hitbox != null)

			hitbox = FlxDestroyUtil.destroy(hitbox);

		#end

	}
