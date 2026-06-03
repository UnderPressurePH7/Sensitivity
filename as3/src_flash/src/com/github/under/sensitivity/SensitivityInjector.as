package com.github.under.sensitivity
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.utils.Dictionary;
   import net.wg.gui.components.controls.Slider;
   import net.wg.gui.lobby.settings.ControlsSettings;
   import net.wg.infrastructure.base.AbstractView;
   import net.wg.infrastructure.events.LoaderEvent;
   import net.wg.infrastructure.managers.impl.ContainerManagerBase;
   import scaleform.clik.events.SliderEvent;
   
   public class SensitivityInjector extends AbstractView
   {
      private var _controls:ControlsSettings = null;
      private var _labels:Dictionary = null;
      
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
         addEventListener(Event.ENTER_FRAME,this.onEnterFrame,false,0,true);
         this.attachToControls();
      }
      
      override protected function onDispose() : void
      {
         removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
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
         this._controls = null;
         this._labels = null;
         super.onDispose();
      }
      
      private function onViewLoaded(param1:LoaderEvent) : void
      {
         this.attachToControls();
      }
      
      private function onEnterFrame(param1:Event) : void
      {
         if(this._controls != null && this._controls.stage == null)
         {
            this.detachLabels();
            this._controls = null;
         }
         this.attachToControls();
      }
      
      private function onStageResize(param1:Event) : void
      {
         this.positionLabels();
      }
      
      private function attachToControls() : void
      {
         var controls:ControlsSettings = this.findControls(App.instance as DisplayObjectContainer);
         if(controls == null || controls == this._controls)
         {
            return;
         }
         this.detachLabels();
         this._controls = controls;
         this.bindSlider(controls.mouseArcadeSensSlider);
         this.bindSlider(controls.mouseSniperSensSlider);
         this.bindSlider(controls.mouseStrategicSensSlider);
         this.bindSlider(controls.mouseAssistAimSensSlider);
         this.bindSlider(controls.mouseDeathFreecamSensSlider);
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
         param2.x = param1.x + param1.width + 8;
         param2.y = param1.y - 5;
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

