package achievement.notifications
{
	import achievement.core.Medal;
	import achievement.events.NotificationEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.TextField;
	import starling.utils.HAlign;
	import starling.utils.VAlign;
	
	public class StarlingUnlockNotifier extends EventDispatcher implements IAchievementNotify
	{
		
		private var _alignment:String;
		private var _stage:Stage;
		private var _bounds:Rectangle;
		private var _rectangle:Sprite;
		private var _notifyTextField:TextField;
		private var _medalNameTextField:TextField;
		private var _pointsTextField:TextField;
		
		private var _rectFillColor:uint;
		private var _notifyTextColor:uint;
		private var _medalNameTextColor:uint;
		private var _pointsTextColor:uint;
		private var _transparency:Number;
		
		private var _startYPos:Number;
		private var _endYPos:Number;
		private var _direction:int;
		private var _active:Boolean;
		private var _retreatDelayTimer:Timer;
		private var _retreatTimeInMillis:uint;
		private var _retreating:Boolean;
		private var _speed:int;
		private var _busy:Boolean = false;
		private var _queue:Array = [];
		
		
		public function StarlingUnlockNotifier(stage:Stage, alignment:String = NotificationAlign.BOTTOM,
											   theme:Object = NotificationTheme.DARK, delayInMillis:uint = 1500, speed:int = 4)
		{
			_stage = stage;
			_speed = speed;
			_retreatTimeInMillis = delayInMillis;
			_bounds = new Rectangle( 0,0,stage.stageWidth, stage.stageHeight );
			_transparency = 1;
			_active = false;
			_alignment = alignment;
			
			_rectFillColor = theme.bg;
			_notifyTextColor = theme.notify;
			_medalNameTextColor = theme.medalName;
			_pointsTextColor = theme.points;
		}
		
		
		private function getFromPercentage( percentage:Number, value:Number ):Number
		{
			return (value / 100) * percentage;
		}
		
		
		public function notify(medal:Medal):void
		{
			if( _busy )
			{
				_queue.push(medal);
			}
			else
			{
				_busy = true;
				_rectangle = new Sprite();
				_stage.addChild(_rectangle);
				var quad:Quad = new Quad(100,100,_rectFillColor);
				quad.alpha = _transparency;
				_rectangle.addChild(quad);
				
				var notificationWidth:Number;
				var notificationHeight:Number = getFromPercentage(15, _stage.stageHeight);
				
				if( _stage.stageHeight > _stage.stageWidth )
				{
					notificationWidth = _stage.stageWidth;
					quad.x = quad.y = 0;
					quad.width = notificationWidth;
					quad.height = notificationHeight;
				}	
				else
				{
					notificationWidth = _stage.stageWidth / 2;
					quad.x = quad.y = 0;
					quad.width = notificationWidth;
					quad.height = notificationHeight;
					_rectangle.x = notificationWidth - notificationWidth / 2;
				}
				
				if( _alignment == NotificationAlign.BOTTOM )
				{
					_startYPos = _stage.stageHeight;
					_endYPos = _stage.stageHeight - getFromPercentage(15, _stage.stageHeight);
					_direction = -1;
				}
				else
				{
					_startYPos = -getFromPercentage(15, _stage.stageHeight);
					_endYPos = 0;
					_direction = 1;
				}
				_rectangle.y = _startYPos;
				
				_notifyTextField = new TextField(quad.width,quad.height,"Achievement Unlocked!");
				_notifyTextField.bold = true;
				_notifyTextField.hAlign = HAlign.CENTER;
				_notifyTextField.fontSize = Math.floor(_stage.stageHeight / 32);
				_notifyTextField.color = _notifyTextColor;
				_notifyTextField.autoScale = true;
				
				_notifyTextField.text = "Achievement Unlocked!";
				_notifyTextField.y = (getFromPercentage(30, notificationHeight) / 2) - (_notifyTextField.height/2);
				_notifyTextField.x = (notificationWidth / 2) - (_notifyTextField.width / 2);
				
				_rectangle.addChild(_notifyTextField);
				
				_medalNameTextField = new TextField(quad.width,quad.height,medal.name);
				_medalNameTextField.bold = true;
				_medalNameTextField.hAlign = HAlign.CENTER;
				_medalNameTextField.fontSize = Math.floor(_stage.stageHeight / 32);
				_medalNameTextField.color = _medalNameTextColor;
				_medalNameTextField.autoScale = true;
				
				_medalNameTextField.text = medal.name;
				_medalNameTextField.y = _notifyTextField.y + (_notifyTextField.textBounds.height);
				_medalNameTextField.x = (notificationWidth / 2) - (_medalNameTextField.width / 2);
				
				_rectangle.addChild(_medalNameTextField);
				
				if( medal.pointsValue != 0 )
				{
					_pointsTextField = new TextField(quad.width,quad.height,"0");
					_pointsTextField.bold = false;
					_pointsTextField.hAlign = HAlign.CENTER;
					_pointsTextField.vAlign = VAlign.BOTTOM;
					_pointsTextField.fontSize = Math.floor(_stage.stageHeight / 40);
					_pointsTextField.color = _pointsTextColor;
					_pointsTextField.autoScale = true;
					
					_pointsTextField.text = medal.pointsValue.toString() + "ap";
					_pointsTextField.y = notificationHeight - (_pointsTextField.height);
					_pointsTextField.x = (notificationWidth / 2) - (_pointsTextField.width / 2);
					
					_rectangle.addChild(_pointsTextField);
				}
				
				_active = true;
				_retreating = false;
				_rectangle.addEventListener(Event.ENTER_FRAME, updateNotification);
				_rectangle.addEventListener(TouchEvent.TOUCH, onNotificationClick);
			}
		}
		
		
		protected function onNotificationClick(event:TouchEvent):void
		{
			if( event.getTouch(_rectangle).phase == TouchPhase.BEGAN )
			{
				_rectangle.removeEventListener(TouchEvent.TOUCH, onNotificationClick);
				dispatchEvent( new NotificationEvent(NotificationEvent.NOTIFICATION_CLICKED) );
			}
		}	
		
		
		protected function updateNotification(event:Event):void
		{
			if( !_active ) return;
			animateNotification();
		}
		
		
		private function animateNotification():void
		{
			_rectangle.y += _direction * _speed;
			
			if( !_retreating )
			{
				if( (_rectangle.y >= _endYPos && _direction == 1) || (_rectangle.y <= _endYPos && _direction == -1) ) 
				{
					_rectangle.y = _endYPos;
					waitAndSwitch();
					_active = false;
					_retreating = true;
				}
			}
			else
			{
				if( (_rectangle.y <= _startYPos && _direction == -1) || (_rectangle.y >= _startYPos && _direction == 1) )
				{
					_rectangle.removeEventListener(Event.ENTER_FRAME, updateNotification);
					_stage.removeChild(_rectangle);
					_active = false;
					_retreating = false;
					_rectangle = null;
					
					if( _queue.length != 0 )
					{
						_busy = false;
						notify(_queue.shift());
					}
				}
			}
		}
		
		
		private function waitAndSwitch():void
		{
			_retreatDelayTimer = new Timer(_retreatTimeInMillis,1);
			_retreatDelayTimer.addEventListener(TimerEvent.TIMER, function(evt:TimerEvent):void
			{
				_active = true;
				_direction = _direction == -1 ? 1 : -1;
			});
			_retreatDelayTimer.start();
		}
		
		
	}
	
}