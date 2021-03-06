
import Snowflake.UI.Datastructures.Console;
import Snowflake.UI.Datastructures.Game;
import Snowflake.UI.Datastructures.SnowflakeSettings;
import Snowflake.UI.Util.*;


import com.rational.serialization.json.JSON;

import flash.utils.ByteArray;
import flash.display.*;
import flash.events.*;
import flash.filesystem.*;
import flash.net.*;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.events.EffectEvent;

import spark.components.Group;
import spark.events.IndexChangeEvent;

[Bindable("fadeInDuration")]
private var fadeInDuration:Number = 500;
[Bindable("fadeOutDuration")]
private var fadeOutDuration:Number = 250;

public var skinName:String="Snowflake_Default";
private var jsonConsoles:String;
private var arrayLength:int;
public var selectedIndex:int = 0;
public var consoleArray:Array = new Array();
private var inTransition:Boolean = false;
[Bindable("listArray")]
private var listArray:ArrayCollection = new ArrayCollection();




/**
 * Gets the zero-relative length of a given array
 * @param array Any array
 * @return The length of the array
 */


private function init(stage:Stage):void{
	
	GeneralUtils.skinLog("SnowflakeUI Loaded at "+ GeneralUtils.getDateString());
	GeneralUtils.skinLog("Skin name is "+skinName);
	stage.nativeWindow.maximize();
	GeneralUtils.skinLog("Display State = Maximized Window");
	
	
	//stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
	//GeneralUtils.skinLog("Display State = Fullscreen");
	
	stage.addChild(new FPSCounter(10,10,0x000000,false,0x000000));
	
	//load background
	GeneralUtils.loadSWF(backgroundArea,"assets/snowflakebg.swf");
	
	GeneralUtils.skinLog("FPS Counter initialized");
	stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDown);
	GeneralUtils.skinLog("Keyboard event listener hooked");
	//trace(loadJson());

	ConsoleUtils.insertConsole(new Console("assets/SNES.png","Super Nintendo Entertainment System","SNES",0),consoleArray);
	ConsoleUtils.insertConsole(new Console("assets/NES.png","Nintendo Entertainment System","NES",1),consoleArray);
	ConsoleUtils.insertConsole(new Console("assets/genesis.png","Sega Genesis","Genesis",2),consoleArray);
	ConsoleUtils.insertConsole(new Console("assets/MasterSystem.png","Sega Master System","SMS",3),consoleArray);
	ConsoleUtils.insertConsole(new Console("assets/n64.png","Nintendo 64","N64",4),consoleArray);
	var gameListTest:Array = new Array();
	gameListTest.push(new Game("Super Mario World","c:/snes/smw.smc","SMW is a platformer","1990","assets/smwcover.png","Nintendo",Game.getConsoleByShortname(consoleArray,"SNES")));
	gameListTest.push(new Game("Super Mario World 2","c:/snes/smw.smc","SMW 2 is not a real game","1990","assets/smwcover.png","Unknown",Game.getConsoleByShortname(consoleArray,"SNES")));
	
	//array.length is not zero indexed, so we subtract one.
	arrayLength = consoleArray.length - 1;
	GeneralUtils.skinLog("Final ArrayLength is "+String(arrayLength));
	GeneralUtils.skinLog("Inserted "+String(arrayLength+1)+" consoles");
	updateConsole();
	socketListen();
	listArray = new ArrayCollection(gameListTest);
	refreshRomMenu(0,true);
	
	
}


/**
 * Updates the console on the screen depending on selectedIndex
 */
private function updateConsole():void{
	
	
	if(selectedIndex>arrayLength){
		selectedIndex = 0;
		
	}
	if(selectedIndex<0){
		selectedIndex = arrayLength;
	}
	var rightIndex:int = selectedIndex + 1
	var leftIndex:int = selectedIndex - 1
	
	if(rightIndex>arrayLength){
		rightIndex=0;
	}
	if(leftIndex<0){
		leftIndex = arrayLength
	}
	
	GeneralUtils.skinLog("===================Console Switched===================");
	var currentConsole:Console = Console(consoleArray[selectedIndex]);
	var debugText:String="SelectedIndex= "+String(selectedIndex)+" ImagePath= "+currentConsole.imagePath+" ConsoleName= "+currentConsole.consoleName+" ShortName= "+currentConsole.shortName;
	GeneralUtils.skinLog(debugText);
	GeneralUtils.skinLog("RightIndex= "+String(rightIndex)+" RightConsole= "+Console(consoleArray[rightIndex]).consoleName);
	GeneralUtils.skinLog("LeftIndex= "+String(leftIndex)+" LeftConsole= "+Console(consoleArray[leftIndex]).consoleName);
	
	consoleLeft.text=Console(consoleArray[leftIndex]).shortName;
	consoleCenter.text=Console(consoleArray[selectedIndex]).shortName;
	consoleRight.text=Console(consoleArray[rightIndex]).shortName;
	label.text=debugText;
	image.source=Console(consoleArray[selectedIndex]).imagePath;
}

protected function FadeBtn_clickHandler(event:MouseEvent):void
{
	
	fadeOut.play();
}

protected function fadeOut_effectEndHandler(event:EffectEvent):void
{
	
	updateConsole();
	fadeIn.play();
}

protected function fadeOut_effectStartHandler(event:EffectEvent):void
{
	
	inTransition = true;
}

protected function fadeIn_effectEndHandler(event:EffectEvent):void
{
	inTransition = false;
}

private function keyDown(event:KeyboardEvent):void
{
	if(!inTransition){
		if(event.keyCode == Keyboard.LEFT){
			selectedIndex--
				fadeOut.play();
		}
		if(event.keyCode == Keyboard.RIGHT){
			selectedIndex++
				fadeOut.play();
		}
	}
	
	if(event.shiftKey){
		switch ( event.keyCode )
		{
			case Keyboard.BACKSPACE : 
				
				MenuContainer.selectedChild = RomMenu;
				
				break;
		}
	}
	if( event.keyCode == Keyboard.ESCAPE )
	{
		event .preventDefault();
	}
}

private function getGameLabel(game:Game):String {
	return game.gameName
}

private function updateList(event:IndexChangeEvent):void{
	refreshRomMenu(list.selectedIndex);
}

private function refreshRomMenu(index:int,refreshDataProvider:Boolean=false):void{
	if(refreshDataProvider){
		list.dataProvider = listArray;
	}
	var game:Game = Game(listArray[index]);
	gameCover.source=game.coverPath;
	releaseYearLabel.text="Release Year: "+game.releaseYear;
	descriptionBox.text=game.gameDescription;
	gameTitleLabel.text=game.gameName;
	publisherLabel.text="Publisher: "+game.publisherName;
	try{
	consoleLabel.text = "Console: "+game.console.consoleName;
	}catch(error:Error){
	consoleLabel.text = "Console: Unknown";
	}
	
}

var socket:Socket = new Socket();

public function socketListen():void
{
	
	this.socket.addEventListener(Event.CONNECT, onConnect);
	this.socket.addEventListener(Event.CLOSE, onClose);
	this.socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
	this.socket.addEventListener(ProgressEvent.SOCKET_DATA, onResponse);
	this.socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
	
	this.socket.connect("localhost",6993);
	
	
	
}

function onConnect(e:Event):void {
	
	GeneralUtils.skinLog("Connected to Socket");
	
	//this.socket.writeUTFBytes("TestCommand:0")
	this.socket.writeUTFBytes("TestCommand\n")
	//this.socket.writeUTFBytes("\nThis is a second string");
}

function onClose(e:Event):void {
	// Security error is thrown if this line is excluded
	this.socket.close();
}

function onError(e:IOErrorEvent):void {
	trace("IO Error: "+e);
}

function onSecError(e:SecurityErrorEvent):void {
	trace("Security Error: "+e);
}

function onResponse(e:ProgressEvent):void {
	if (this.socket.bytesAvailable>0) {
		trace(this.socket.readUTFBytes(this.socket.bytesAvailable));
	}
	
}

function getByteLength (s:String):Number {
	var byteArray:ByteArray = new ByteArray();
	byteArray.writeUTFBytes(s);
	return byteArray.length;
}