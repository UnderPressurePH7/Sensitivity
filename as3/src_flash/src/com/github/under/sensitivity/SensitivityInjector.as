package com.github.under.sensitivity
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.utils.clearTimeout;
   import flash.utils.Dictionary;
   import flash.utils.setTimeout;
   import net.wg.gui.components.controls.Slider;
   import net.wg.gui.lobby.settings.ControlsSettings;
   import net.wg.infrastructure.base.AbstractView;
   import net.wg.infrastructure.events.LoaderEvent;
   import net.wg.infrastructure.managers.impl.ContainerManagerBase;
   import scaleform.clik.events.SliderEvent;
   
   public class SensitivityInjector extends AbstractView
   {
      private static const LABEL_OFFSET_X:int = 0;
      private static const LABEL_OFFSET_Y:int = -5;
      private static const ATTACH_RETRY_DELAY:int = 150;
      private static const ATTACH_RETRY_ATTEMPTS:int = 20;
      private static const IDLE_ATTACH_RETRY_DELAY:int = 1000;
      
      private var _controls:ControlsSettings = null;
      private var _labels:Dictionary = null;
      private var _attachRetryTimer:uint = 0;
      private var _attachRetryAttempts:int = 0;
      private var _attachRetryIdle:Boolean = false;
      
      public function SensitivityInjector()
      {
         super();
         this._labels = new Dictionary(true);
      }
      
      override protected function configUI() : void
      {
         super.configUI();
         var manager:ContainerManagerBase = App.containerMgr as ContainerManagerBase;
         if(manager != null && manager.loader != null)
         {
            manager.loader.addEventListener(LoaderEvent.VIEW_LOADED,this.onViewLoaded,false,0,true);
         }
         if(App.instance != null && App.instance.stage != null)
         {
            App.instance.stage.addEventListener(Event.RESIZE,this.onStageResize,false,0,true);
         }
         if(!this.attachToControls())
         {
            this.startAttachRetry();
         }
      }
      
      override protected function onDispose() : void
      {
         var manager:ContainerManagerBase = App.containerMgr as ContainerManagerBase;
         if(manager != null && manager.loader != null)
         {
            manager.loader.removeEventListener(LoaderEvent.VIEW_LOADED,this.onViewLoaded);
         }
         if(App.instance != null && App.instance.stage != null)
         {
            App.instance.stage.removeEventListener(Event.RESIZE,this.onStageResize);
         }
         this.detachLabels();
         this.clearAttachRetry();
         this._controls = null;
         this._labels = null;
         super.onDispose();
      }
      
      private function onViewLoaded(param1:LoaderEvent) : void
      {
         if(!this.attachToControls())
         {
            this.startAttachRetry();
         }
      }
      
      private function onStageResize(param1:Event) : void
      {
         if(this._controls == null)
         {
            if(!this.attachToControls())
            {
               this.startAttachRetry();
            }
            return;
         }
         this.positionLabels();
      }
      
      private function attachToControls() : Boolean
      {
         var controls:ControlsSettings = this.findControls(App.instance as DisplayObjectContainer);
         if(controls == null)
         {
            return false;
         }
         if(controls == this._controls)
         {
            this.positionLabels();
            return true;
         }
         this.detachLabels();
         this.clearAttachRetry();
         this._controls = controls;
         this._controls.addEventListener(Event.REMOVED_FROM_STAGE,this.onControlsRemoved,false,0,true);
         this.bindSlider(controls.mouseArcadeSensSlider);
         this.bindSlider(controls.mouseSniperSensSlider);
         this.bindSlider(controls.mouseStrategicSensSlider);
         this.bindSlider(controls.mouseAssistAimSensSlider);
         this.bindSlider(controls.mouseDeathFreecamSensSlider);
         return true;
      }

      private function startAttachRetry() : void
      {
         if(this._controls != null)
         {
            return;
         }
         this.clearAttachRetry();
         this._attachRetryIdle = false;
         this.scheduleAttachRetry();
      }

      private function scheduleAttachRetry() : void
      {
         if(this._attachRetryTimer != 0)
         {
            clearTimeout(this._attachRetryTimer);
         }
         this._attachRetryTimer = setTimeout(this.checkAttachRetry,this._attachRetryIdle ? IDLE_ATTACH_RETRY_DELAY : ATTACH_RETRY_DELAY);
      }

      private function checkAttachRetry() : void
      {
         this._attachRetryTimer = 0;
         if(this._controls != null)
         {
            return;
         }
         this._attachRetryAttempts++;
         if(this._attachRetryAttempts >= ATTACH_RETRY_ATTEMPTS)
         {
            this._attachRetryIdle = true;
         }
         if(!this.attachToControls())
         {
            this.scheduleAttachRetry();
         }
      }

      private function clearAttachRetry() : void
      {
         if(this._attachRetryTimer != 0)
         {
            clearTimeout(this._attachRetryTimer);
            this._attachRetryTimer = 0;
         }
         this._attachRetryAttempts = 0;
         this._attachRetryIdle = false;
      }

      private function onControlsRemoved(param1:Event) : void
      {
         if(this._controls != null)
         {
            this._controls.removeEventListener(Event.REMOVED_FROM_STAGE,this.onControlsRemoved);
         }
         this.detachLabels();
         this._controls = null;
      }
      
      private function findControls(param1:DisplayObjectContainer) : ControlsSettings
      {
         var child:DisplayObject = null;
         var result:ControlsSettings = null;
         if(param1 == null)
         {
            return null;
         }
         var count:int = param1.numChildren;
         var index:int = 0;
         while(index < count)
         {
            child = param1.getChildAt(index);
            if(child is ControlsSettings)
            {
               return child as ControlsSettings;
            }
            if(child is DisplayObjectContainer)
            {
               result = this.findControls(child as DisplayObjectContainer);
               if(result != null)
               {
                  return result;
               }
            }
            index++;
         }
         return null;
      }
      
      private function bindSlider(param1:Slider) : void
      {
         if(param1 == null || this._controls == null)
         {
            return;
         }
         var label:SensitivityValueLabel = new SensitivityValueLabel();
         this._labels[param1] = label;
         this._controls.addChild(label);
         param1.addEventListener(SliderEvent.VALUE_CHANGE,this.onSliderValueChange,false,0,true);
         this.positionLabel(param1,label);
         this.updateLabel(param1,label);
      }
      
      private function detachLabels() : void
      {
         var slider:Object = null;
         var label:SensitivityValueLabel = null;
         if(this._labels == null)
         {
            return;
         }
         if(this._controls != null)
         {
            this._controls.removeEventListener(Event.REMOVED_FROM_STAGE,this.onControlsRemoved);
         }
         for(slider in this._labels)
         {
            Slider(slider).removeEventListener(SliderEvent.VALUE_CHANGE,this.onSliderValueChange);
            label = this._labels[slider] as SensitivityValueLabel;
            if(label != null)
            {
               label.dispose();
            }
            delete this._labels[slider];
         }
      }
      
      private function positionLabels() : void
      {
         var slider:Object = null;
         var label:SensitivityValueLabel = null;
         if(this._labels == null)
         {
            return;
         }
         for(slider in this._labels)
         {
            label = this._labels[slider] as SensitivityValueLabel;
            this.positionLabel(Slider(slider),label);
         }
      }
      
      private function positionLabel(param1:Slider, param2:SensitivityValueLabel) : void
      {
         if(param1 == null || param2 == null)
         {
            return;
         }
         param2.x = param1.x + param1.width + LABEL_OFFSET_X;
         param2.y = param1.y + LABEL_OFFSET_Y;
      }
      
      private function onSliderValueChange(param1:SliderEvent) : void
      {
         var slider:Slider = param1.target as Slider;
         this.updateLabel(slider,this._labels[slider] as SensitivityValueLabel);
      }
      
      private function updateLabel(param1:Slider, param2:SensitivityValueLabel) : void
      {
         if(param1 == null || param2 == null)
         {
            return;
         }
         param2.text = String(this.sliderToPercent(param1));
      }
      
      private function sliderToPercent(param1:Slider) : int
      {
         if(param1.maximum == param1.minimum)
         {
            return 0;
         }
         return Math.round((param1.value - param1.minimum) / (param1.maximum - param1.minimum) * 100);
      }
   }
}
