package com.github.under.sensitivity
{
   import flash.display.DisplayObjectContainer;
   import flash.text.AntiAliasType;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   
   public class SensitivityValueLabel extends TextField
   {
      private static const WIDTH:int = 44;
      private static const HEIGHT:int = 22;
      private static const FONT:String = "$FieldFont";
      private static const SIZE:int = 13;
      private static const COLOR:uint = 9868934;
      
      public function SensitivityValueLabel()
      {
         super();
         var format:TextFormat = new TextFormat(FONT,SIZE,COLOR,true);
         format.align = TextFormatAlign.CENTER;
         defaultTextFormat = format;
         setTextFormat(format);
         width = WIDTH;
         height = HEIGHT;
         autoSize = TextFieldAutoSize.NONE;
         selectable = false;
         mouseEnabled = false;
         mouseWheelEnabled = false;
         antiAliasType = AntiAliasType.ADVANCED;
      }
      
      public function dispose() : void
      {
         var container:DisplayObjectContainer = parent;
         if(container != null)
         {
            container.removeChild(this);
         }
      }
   }
}

