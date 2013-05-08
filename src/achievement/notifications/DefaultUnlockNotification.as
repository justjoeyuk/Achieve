package achievement.notifications
{
	import achievement.core.Medal;
	import achievement.events.NotificationEvent;
	
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import flashx.textLayout.formats.TextAlign;
	
	
	public class DefaultUnlockNotification extends EventDispatcher implements IAchievementNotify
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
		private var _queue:Array =[];
		private var _busy:Boolean = false;
		
		
		public function DefaultUnlockNotification( stage:Stage, theme:Object, alignment:String = NotificationAlign.BOTTOM,
												   delayInMillis:uint = 1500, speed:int = 4 )
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
		
		
		/**
		 * <p>This will inform the user that they 
		 * have obtained an Achievement, and 
		 * usually have a visual representation. 
		 * When the notification is clicked, it 
		 * will fire an Event you can collect using, 
		 * NotifyEvent.NOTIFY_CLICKED which will 
		 * take a <code>Medal</code> as a parameter</p>
		 * 
		 * @param medal -- The medal which has been achieved.
		 */
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
				_rectangle.buttonMode = true;
				_stage.addChild(_rectangle);
				
				_rectangle.graphics.beginFill(_rectFillColor, _transparency);
				var notificationWidth:Number;
				var notificationHeight:Number = getFromPercentage(15, _stage.stageHeight);
				
				if( _stage.stageHeight > _stage.stageWidth )
				{
					notificationWidth = _stage.stageWidth;
					_rectangle.graphics.drawRect(0,0, notificationWidth, notificationHeight);
				}	
				else
				{
					notificationWidth = _stage.stageWidth / 2;
					_rectangle.graphics.drawRect( 0, 0,
												  notificationWidth, notificationHeight);
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
				
				var notificationTextFormat:TextFormat = new TextFormat("Arial", Math.floor(_stage.stageHeight / 32), _notifyTextColor, true, null, null, null, null, TextAlign.CENTER );
				var medalNameFormat:TextFormat = new TextFormat("Arial", Math.floor(_stage.stageHeight / 32), _medalNameTextColor, true, null, null, null, null, TextAlign.CENTER);
				var pointsFormat:TextFormat = new TextFormat("Arial", Math.floor( _stage.stageHeight / 40 ), _pointsTextColor, true, null, null, null, null, TextAlign.CENTER);
				
				_notifyTextField = new TextField();
				_notifyTextField.defaultTextFormat = notificationTextFormat;
				_notifyTextField.autoSize = TextFieldAutoSize.CENTER;
				
				_notifyTextField.text = "Achievement Unlocked!";
				_notifyTextField.y = (getFromPercentage(30, notificationHeight) / 2) - (_notifyTextField.height/2);
				_notifyTextField.x = (notificationWidth / 2) - (_notifyTextField.width / 2);
				
				_rectangle.addChild(_notifyTextField);
				
				_medalNameTextField = new TextField();
				_medalNameTextField.defaultTextFormat = medalNameFormat;
				_medalNameTextField.autoSize = TextFieldAutoSize.CENTER;
				
				_medalNameTextField.text = medal.name;
				_medalNameTextField.y = _notifyTextField.y + (_notifyTextField.height);
				_medalNameTextField.x = (notificationWidth / 2) - (_medalNameTextField.width / 2);
				
				_rectangle.addChild(_medalNameTextField);
				
				if( medal.pointsValue != 0 )
				{
					_pointsTextField = new TextField();
					_pointsTextField.defaultTextFormat = pointsFormat;
					_pointsTextField.autoSize = TextFieldAutoSize.CENTER;
					
					_pointsTextField.text = medal.pointsValue.toString() + "ap";
					_pointsTextField.y = notificationHeight - (_pointsTextField.height);
					_pointsTextField.x = (notificationWidth / 2) - (_pointsTextField.width / 2);
					
					_rectangle.addChild(_pointsTextField);
				}
				
				_rectangle.cacheAsBitmap = true;
				_active = true;
				_retreating = false;
				_rectangle.addEventListener(Event.ENTER_FRAME, updateNotification);
				_rectangle.addEventListener(MouseEvent.CLICK, onNotificationClick);
			}
		}
		
		
		protected function onNotificationClick(event:MouseEvent):void
		{
			_rectangle.removeEventListener(MouseEvent.CLICK, onNotificationClick);
			dispatchEvent( new NotificationEvent(NotificationEvent.NOTIFICATION_CLICKED) );
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
					_rectangle = null;
					_active = false;
					_retreating = false;
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