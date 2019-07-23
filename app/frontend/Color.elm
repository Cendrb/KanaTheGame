module Color exposing (Color, fromRgb, averageColors, renderColor, toCssColor, colorDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DPipeline
import Css

type alias Color =
  {
    r : Int,
    g : Int,
    b : Int
  }

fromRgb : Int -> Int -> Int -> Color
fromRgb = Color

averageColors : Color -> Color -> Color
averageColors color1 color2 =
  Color
    ((color1.r + color2.r) // 2)
    ((color1.g + color2.g) // 2)
    ((color1.b + color2.b) // 2)

renderColor : Color -> String
renderColor color =
  "rgb(" ++ String.fromInt color.r ++ "," ++  String.fromInt color.g ++ "," ++  String.fromInt color.b ++ ")"

toCssColor : Color -> Css.Color
toCssColor color =
  Css.rgb color.r color.g color.b

colorDecoder : Decode.Decoder Color
colorDecoder =
  Decode.succeed Color
    |> DPipeline.required "r" Decode.int
    |> DPipeline.required "g" Decode.int
    |> DPipeline.required "b" Decode.int
