port module Main exposing (..)

import Color

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as DPipeline

import Browser
import List.Extra
import Dict exposing (Dict)
import Set exposing (Set)
import Css
import Debug
import Css.Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attributes
import Html.Styled.Events as Events
import Html
import Svg
import Svg.Keyed
import Svg.Attributes
import Svg.Events
import Svg.Styled
import Svg.Styled.Attributes
import Svg.Styled.Events

-- MODEL

type alias Model =
  {
    state : State,
    signups : Dict Int Signup,
    role : Role,
    errorMessage : String,
    board : Board
  }

type State
  = Playing
  | Waiting
  | Finished

type Role
  = Player Int -- player id
  | Spectator

type alias Board =
  {
    x : Int,
    y : Int,
    stones : Dict Int Stone,
    shapes : List Shape,
    selectedStoneId : Maybe Int,
    currentPlayerId : Maybe Int
  }

type alias Stone =
  {
    id : Int,
    coords : (Int, Int),
    playerId : Int
  }

type alias Shape =
  {
    id : Int,
    playerId : Int,
    playerColor : Color.Color,
    name : String,
    points : Int,
    traded : Bool,
    stones : List Stone,
    edges : List Edge,
    vertices : Set (Int, Int)
  }

type alias Edge =
  {
    from : (Int, Int),
    to : (Int, Int)
  }

type alias Signup =
  {
    userName : String,
    playerId : Int,
    spentPoints : Int,
    color : Color.Color
  }

type alias BoardParameters =
  {
    unit : Float,
    offset : Float
  }

type alias Flags =
  {
    state : String,
    signups : Decode.Value,
    role : Decode.Value,
    board : Decode.Value
  }

-- INIT

init : Flags -> (Model, Cmd Message)
init flags =
  (Model
      (case parseStateString flags.state of
        Ok state -> state
        Err error -> error |> Debug.todo)
      (case Decode.decodeValue signupsDecoder flags.signups of
        Ok signups -> signups |> toDictionaryWithKey .playerId
        Err error -> error |> Decode.errorToString |> Debug.todo)
      (case decodeRole flags.role of
        Ok role -> role
        Err error -> error |> Debug.todo)
      ""
      (case Decode.decodeValue boardDecoder flags.board of
        Ok board -> board
        Err error -> error |> Decode.errorToString |> Debug.todo)
    , Cmd.none)
      

-- VIEW

stateToString s =
  case s of
    Playing -> "playing"
    Waiting -> "waiting"
    Finished -> "finished"

renderRole role =
  case role of
    Player id -> "playing with ID " ++ String.fromInt id
    Spectator -> "spectating"

createCoordinateTuples : Int -> Int -> List (Int, Int)
createCoordinateTuples x y = -- non-inclusive on the end
  List.range 0 (x - 1)
    |> List.concatMap (
      \xOff -> (List.range 0 (y - 1)) -- add y variants for each x
        |> List.map (\yOff -> (xOff, yOff))
    )

renderGridCircle : BoardParameters -> (Dict (Int, Int) Color.Color) -> (Int, Int) -> Svg.Styled.Svg Message
renderGridCircle params shapesDict coords =
  case Dict.get coords shapesDict of
    Just color ->
      Svg.Styled.circle
      [
        Svg.Styled.Attributes.r "4.3",
        Svg.Styled.Attributes.cx <| String.fromFloat (toFloat (Tuple.first coords) * params.unit + params.offset - 2),
        Svg.Styled.Attributes.cy <| String.fromFloat (toFloat (Tuple.second coords) * params.unit + params.offset - 2),
        Svg.Styled.Attributes.css [
          Css.fill <| Color.toCssColor <| color
        ]
      ] []
    Nothing ->
      Svg.Styled.circle
      [
        Svg.Styled.Attributes.r "4.3",
        Svg.Styled.Attributes.cx <| String.fromFloat (toFloat (Tuple.first coords) * params.unit + params.offset - 2),
        Svg.Styled.Attributes.cy <| String.fromFloat (toFloat (Tuple.second coords) * params.unit + params.offset - 2),
        Svg.Styled.Attributes.css [
          Css.fill <| Css.rgb 255 255 255
        ]
      ] []

renderGridEdge : BoardParameters -> (Edge, Color.Color) -> Svg.Styled.Svg Message
renderGridEdge params (edge, color) =
  let
    offset = -2
  in
    Svg.Styled.line [
      Svg.Styled.Attributes.x1 <| String.fromFloat <| toFloat(Tuple.first edge.from) * params.unit + params.offset + offset,
      Svg.Styled.Attributes.y1 <| String.fromFloat <| toFloat(Tuple.second edge.from) * params.unit + params.offset + offset,
      Svg.Styled.Attributes.x2 <| String.fromFloat <| toFloat(Tuple.first edge.to) * params.unit + params.offset + offset,
      Svg.Styled.Attributes.y2 <| String.fromFloat <| toFloat(Tuple.second edge.to) * params.unit + params.offset + offset,
      Svg.Styled.Attributes.stroke <| Color.renderColor <| color,
      Svg.Styled.Attributes.strokeWidth "1.5"
    ] []

getShapePriorityColor : Shape -> Int -> item -> (item, Color.Color)
getShapePriorityColor shape priority item =
  (item, Color.fromRgb 
    255
    (255 - priority * 70)
    0
  )

renderGridElements : Int -> Int -> (List Shape) -> BoardParameters -> List (Svg.Styled.Svg Message)
renderGridElements x y shapes params =
  let
    verticesColorsDict = shapes |> List.Extra.gatherWith (\s1 s2 -> s1.points == s2.points) |> List.indexedMap (
        \index (determiningShape, restShapes) ->
          (restShapes ++ [determiningShape]) |> List.concatMap (
            \shape -> shape.vertices |> Set.toList |> List.map (getShapePriorityColor shape index)
          ) |> Dict.fromList
      ) |> List.foldl Dict.union Dict.empty
    edgesColorsTuples = shapes |> List.Extra.gatherWith (\s1 s2 -> s1.points == s2.points) |> List.indexedMap (
        \index (determiningShape, restShapes) ->
          (restShapes ++ [determiningShape]) |> List.concatMap (
            \shape -> shape.edges |> List.map (getShapePriorityColor shape index)
          )
      ) |> List.concat
  in
    (createCoordinateTuples x y |> List.map (
      \coords -> Svg.Styled.path 
      [
        Svg.Styled.Attributes.d "m6.296296,0l38.407408,0c0.881481,3.022222 3.274074,5.288889 6.296296,6.17037l0,38.407408c-3.022222,0.881481 -5.414815,3.274074 -6.296296,6.296296l-38.407408,0c-0.881481,-3.022222 -3.274074,-5.414815 -6.296296,-6.296296l0,-38.407408c3.022222,-0.881481 5.414815,-3.148148 6.296296,-6.17037z",
        Svg.Styled.Attributes.transform (
          "translate("
          ++ (String.fromFloat (toFloat (Tuple.first coords) * params.unit + params.offset))
          ++ ","
          ++ (String.fromFloat (toFloat (Tuple.second coords) * params.unit + params.offset))
          ++ ") scale(0.9 0.9)"
        ),
        Svg.Styled.Events.onClick (FieldClicked coords),
        Svg.Styled.Attributes.css [
          Css.fill <| Css.rgb 255 255 255
        ]
      ] []
    ))
    ++ (edgesColorsTuples |> List.map (renderGridEdge params))
    ++ (createCoordinateTuples (x + 1) (y + 1) |> List.map (renderGridCircle params verticesColorsDict) )

getGradientIdentifier : Int -> Bool -> String
getGradientIdentifier playerId isSelected =
  "player" ++ String.fromInt playerId ++ "_" ++ if isSelected then "selected" else "regular"

isStoneSelected : Stone -> Maybe Int -> Bool
isStoneSelected stone selectedStoneId =
  case selectedStoneId of
    Just id ->
      stone.id == id
    Nothing ->
      False

renderStones : (List Stone) -> Maybe Int -> BoardParameters -> Svg.Styled.Svg Message
renderStones stones selectedStoneId params =
  let
    offset = 23
    radius = 20
  in
    Svg.Keyed.node "g" [] (stones |> List.map (
      \stone ->
        (String.fromInt stone.id,
          Svg.circle
          [
            Svg.Attributes.r <| String.fromInt radius,
            Svg.Attributes.transform <| (
              "translate("
              ++ String.fromFloat (toFloat (Tuple.first stone.coords) * params.unit + offset + params.offset)
              ++ ","
              ++ String.fromFloat (toFloat (Tuple.second stone.coords) * params.unit + offset + params.offset)
              ++ ")"
            ),
            Svg.Attributes.fill <| "url(#" ++ (getGradientIdentifier stone.playerId (isStoneSelected stone selectedStoneId))++ ")",
            Svg.Attributes.style <| "transition: transform 1s ease-in-out;",
            Svg.Events.onClick (StoneClicked stone)
          ] []
        )
      )
    ) |> Svg.Styled.fromUnstyled

renderColorTransitions : (Dict Int Signup) -> List (Svg.Styled.Svg Message)
renderColorTransitions signups =
  List.concat [
    signups |> Dict.values |> List.map (
      \signup ->
        Svg.Styled.radialGradient [
          Svg.Styled.Attributes.id (getGradientIdentifier signup.playerId False),
          Svg.Styled.Attributes.cx "66%",
          Svg.Styled.Attributes.cy "66%",
          Svg.Styled.Attributes.fx "66%",
          Svg.Styled.Attributes.fy "66%",
          Svg.Styled.Attributes.r "66%"
        ] [
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "0",
            Svg.Styled.Attributes.stopColor <| Color.renderColor <| (Color.averageColors signup.color (Color.fromRgb 300 300 300))
          ] [],
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "0.2",
            Svg.Styled.Attributes.stopColor <| Color.renderColor <| (Color.averageColors signup.color (Color.fromRgb 200 200 200))
          ] [],
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "1",
            Svg.Styled.Attributes.stopColor <| Color.renderColor <| signup.color
          ] []
        ]
    ),
    signups |> Dict.values |> List.map (
      \signup ->
        Svg.Styled.radialGradient [
          Svg.Styled.Attributes.id (getGradientIdentifier signup.playerId True),
          Svg.Styled.Attributes.cx "33%",
          Svg.Styled.Attributes.cy "33%",
          Svg.Styled.Attributes.fx "33%",
          Svg.Styled.Attributes.fy "33%"
        ] [
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "0",
            Svg.Styled.Attributes.stopColor <| Color.renderColor <| (Color.averageColors signup.color (Color.fromRgb 300 300 300))
          ] [],
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "0.270588",
            Svg.Styled.Attributes.stopColor <| Color.renderColor <| (Color.averageColors signup.color (Color.fromRgb 200 200 200))
          ] [],
          Svg.Styled.stop [
            Svg.Styled.Attributes.offset "1",
            Svg.Styled.Attributes.stopColor <| Color.renderColor <| signup.color
          ] []
        ]
    )
  ]

renderShapes : List Shape -> BoardParameters -> Svg.Styled.Svg Message
renderShapes shapes params =
  let
    positionShapeDict = shapes
      |> List.concatMap (\shape -> shape.stones |> List.map (\stone -> (stone.coords, shape)))
      |> Dict.fromList
    offset = -2
  in
    Svg.Styled.g [] (positionShapeDict
       |> Dict.toList
       |> List.map (\((x, y), shape) ->
            Svg.Styled.rect [
              Svg.Styled.Attributes.x <| String.fromFloat <| toFloat(x) * params.unit + params.offset + offset,
              Svg.Styled.Attributes.y <| String.fromFloat <| toFloat(y) * params.unit + params.offset + offset,
              Svg.Styled.Attributes.width <| String.fromFloat <| params.unit,
              Svg.Styled.Attributes.height <| String.fromFloat <| params.unit,
              Svg.Styled.Attributes.fill "transparent",
              Svg.Styled.Events.onClick <| TradeShape shape,
              Svg.Styled.Attributes.css [
                Css.cursor Css.pointer
              ]
            ] []
          )
    )

renderBoard : Board -> (Dict Int Signup) -> Role -> Html Message
renderBoard board signups role =
  let
    params = BoardParameters
      50
      7
    shapesToRender = board.shapes |> List.filter (\shape -> not shape.traded && case role of
        Spectator -> True
        Player id -> shape.playerId == id
      )
  in
    Svg.Styled.svg [
      Svg.Styled.Attributes.viewBox (
        "0 0 "
        ++ String.fromFloat (toFloat board.x * params.unit + params.offset + 2.5)
        ++ " "
        ++ String.fromFloat (toFloat board.y * params.unit + params.offset + 2.5)),
      Svg.Styled.Attributes.css [
        Css.property "flex" "0 0 auto",
        Css.padding <| Css.px 15
      ]
    ] 
    (
      (renderGridElements board.x board.y shapesToRender params)
      ++ [renderStones (board.stones |> Dict.values) board.selectedStoneId params]
      ++ [renderShapes shapesToRender params ]
      ++ [
        Svg.Styled.defs [] (renderColorTransitions signups)
      ]
    )

defaultBackground : Color.Color
defaultBackground = Color.fromRgb 181 183 186

getCurrentSignup : Model -> Maybe Signup
getCurrentSignup model =
  case model.role of
    Player currentPlayerId ->
      model.signups |> Dict.get currentPlayerId
    Spectator ->
      model.signups |> Dict.values |> List.reverse |> List.head

getOtherSignup : Model -> Maybe Signup
getOtherSignup model =
  case model.role of
    Player currentPlayerId ->
      model.signups |> Dict.remove currentPlayerId |> Dict.values |> List.head
    Spectator ->
      model.signups |> Dict.values |> List.head

renderMainGradient: Color.Color -> Color.Color -> Color.Color -> String
renderMainGradient top center bottom =
  "linear-gradient("
    ++ (top |> Color.renderColor)
    ++ "5%"
    ++ ","
    ++ (center |> Color.renderColor)
    ++ ","
    ++ (center |> Color.renderColor)
    ++ ","
    ++ (center |> Color.renderColor)
    ++ ","
    ++ (bottom |> Color.renderColor)
    ++ "85%"
    ++ ")"

renderShapesLibrary : Html Message
renderShapesLibrary =
  button [
    Attributes.css [
        Css.height (Css.rem 9),
        Css.backgroundColor (Css.rgba 0 0 0 0),
        Css.property "border" "none"
      ]
  ] [
    Svg.Styled.svg [
      Svg.Styled.Attributes.viewBox "0 0 600 820",
      Svg.Styled.Attributes.css [
        Css.height (Css.pct 100)
      ]
    ] [
      Svg.Styled.path [
        Svg.Styled.Attributes.fill "white",
        Svg.Styled.Attributes.d "M23 0c13,0 24,10 24,23 0,13 -11,23 -24,23 -12,0 -23,-10 -23,-23 0,-13 11,-23 23,-23zm257 0c13,0 23,10 23,23 0,13 -10,23 -23,23 -13,0 -24,-10 -24,-23 0,-13 11,-23 24,-23zm-257 256c13,0 24,10 24,23 0,13 -11,23 -24,23 -12,0 -23,-10 -23,-23 0,-13 11,-23 23,-23zm257 0c13,0 23,10 23,23 0,13 -10,23 -23,23 -13,0 -24,-10 -24,-23 0,-13 11,-23 24,-23zm256 0c13,0 23,10 23,23 0,13 -10,23 -23,23 -13,0 -23,-10 -23,-23 0,-13 10,-23 23,-23zm-513 256c13,0 24,10 24,23 0,13 -11,24 -24,24 -12,0 -23,-11 -23,-24 0,-13 11,-23 23,-23zm257 0c13,0 23,10 23,23 0,13 -10,24 -23,24 -13,0 -24,-11 -24,-24 0,-13 11,-23 24,-23zm256 0c13,0 23,10 23,23 0,13 -10,24 -23,24 -13,0 -23,-11 -23,-24 0,-13 10,-23 23,-23zm-256 256c13,0 23,11 23,24 0,12 -10,23 -23,23 -13,0 -24,-11 -24,-23 0,-13 11,-24 24,-24zm256 0c13,0 23,11 23,24 0,12 -10,23 -23,23 -13,0 -23,-11 -23,-23 0,-13 10,-24 23,-24z"
      ] [],
      Svg.Styled.path [
        Svg.Styled.Attributes.stroke "white",
        Svg.Styled.Attributes.strokeWidth "14",
        Svg.Styled.Attributes.fill "none",
        Svg.Styled.Attributes.d "M536 535l0 256 -256 0 0 -256 -257 0 0 -256 0 -256 257 0 0 256 256 0 0 256zm-24 222c-4,3 -8,7 -11,11l-187 0c-3,-4 -7,-8 -11,-11l0 -187c8,-6 14,-14 17,-23l176 0c2,9 8,18 16,23l0 187zm-198 -455c-5,8 -13,14 -23,17l0 176c14,4 25,15 29,29l176 0c2,-10 8,-18 16,-24l0 -186c-4,-3 -8,-7 -11,-12l-187 0zm-69 210c5,-8 13,-14 23,-17l0 -176c-14,-4 -25,-15 -29,-28l-175 0c-3,9 -9,17 -17,23l0 186c4,3 8,7 11,12l187 0zm-198 -455c4,-3 8,-7 11,-11l187 0c3,5 7,8 11,12l0 186c-8,6 -14,14 -17,23l-175 0c-3,-9 -9,-17 -17,-23l0 -187z"
      ] []
    ]
  ]

renderEndMove : Html Message
renderEndMove =
  button [
    Attributes.css [
        Css.height (Css.rem 9),
        Css.backgroundColor (Css.rgba 0 0 0 0),
        Css.property "border" "none"
      ]
  ]
  [
    Svg.Styled.svg [
      Svg.Styled.Attributes.viewBox "0 0 600 600",
      Svg.Styled.Attributes.css [
        Css.height (Css.pct 100)
      ]
    ] [
      Svg.Styled.path [
        Svg.Styled.Attributes.stroke "white",
        Svg.Styled.Attributes.strokeWidth "14",
        Svg.Styled.Attributes.fill "none",
        Svg.Styled.Attributes.d "M0 583l0 -292 0 -291 253 145 252 146 -252 146 -253 146zm42 -64l0 -228 0 -227 197 114 197 113 -197 114 -197 114z"
      ] []
    ]
  ]

renderBottomButtons : Html Message
renderBottomButtons =
  let 
    bottomButtonStyle = Attributes.css [
      Css.property "font-family" "futuraMediumBT",
      Css.color (Css.rgb 255 255 255),
      Css.fontSize (Css.rem 2),
      Css.backgroundColor (Css.rgba 0 0 0 0),
      Css.property "border" "none"]
  in
    div [
      Attributes.css [
        Css.displayFlex,
        Css.marginBottom (Css.rem 2),
        Css.padding (Css.rem 1),
        Css.property "align-items" "center",
        Css.property "justify-content" "space-around"
      ]
    ] [
      button [ bottomButtonStyle ] [ text "Surrender" ],
      button [ bottomButtonStyle ] [ text "Extra moves" ]
    ]

getPlayerCssProperties : Bool -> Signup -> List Css.Style
getPlayerCssProperties isCurrent signup = [
    Css.property "text-align" "center",
    Css.fontSize (if isCurrent then (Css.rem 3.6) else (Css.rem 2.2)),
    Css.property "font-family" "futuraMediumBT",
    Css.displayFlex,
    Css.property "align-items" "center",
    Css.property "justify-content" "space-around",
    Css.textShadow4 (Css.px 0) (Css.px 0) (Css.rem 0.3) (Color.toCssColor signup.color),
    Css.height (Css.rem 6),
    Css.color (Css.rgb 255 255 255)
  ]

renderTopScore : Signup -> Board -> Html Message
renderTopScore signup board =
  div [
    Attributes.css (
      getPlayerCssProperties (signup.playerId |> isCurrentlyPlaing board) signup
      ++ [
        Css.marginTop (Css.rem 1.5)
      ]
    )
  ]
  [
    span [] [
      signup.userName
        ++ ": "
        ++ String.fromInt(calculateEarned board.shapes signup.playerId - signup.spentPoints)
      |> text]
  ]

renderBottomScore : Signup -> Board -> Html Message
renderBottomScore signup board =
  div [ 
    Attributes.css 
      ((getPlayerCssProperties (signup.playerId |> isCurrentlyPlaing board) signup)
      ++ [
        Css.paddingLeft (Css.rem 1),
        Css.paddingRight (Css.rem 1)
      ] )
    ]
    [ 
      renderShapesLibrary,
      span [] [
        signup.userName
          ++ ": "
          ++ String.fromInt(calculateEarned board.shapes signup.playerId - signup.spentPoints)
        |> text 
      ],
      renderEndMove
    ]

view : Model -> Html Message
view model =
  case model.errorMessage of
    "" ->
      let
        maybeCurrentSignup = getCurrentSignup model
        maybeOtherSignup = getOtherSignup model
      in
        case maybeCurrentSignup of
          Nothing -> div [] [ text "I'm a little clueless on what to do" ]
          Just currentSignup -> 
            case maybeOtherSignup of
              Nothing -> div [] [ text "I'm a little clueless on what to do" ]
              Just otherSignup -> 
                div [
                  Attributes.css [
                    Css.property "background-image" (renderMainGradient otherSignup.color defaultBackground currentSignup.color),
                    Css.maxWidth <| Css.em 60,
                    Css.height <| Css.pct 100,
                    Css.displayFlex,
                    Css.property "flex-direction" "column",
                    Css.property "justify-content" "space-around"
                  ]
                ] [
                  renderTopScore otherSignup model.board,
                  renderBoard model.board model.signups model.role,
                  renderBottomScore currentSignup model.board,
                  renderBottomButtons
                ]
    _ ->
      div [] [ text model.errorMessage ]


-- MESSAGE

type Message
  = StateReceived (Result String State)
  | SignupsReceived (Result Decode.Error (List Signup))
  | RoleReceived (Result String Role)
  | BoardReceived (Result Decode.Error Board)
  | StoneClicked Stone
  | FieldClicked (Int, Int)
  | TradeShape Shape

-- PORTS
port statePort : (String -> msg) -> Sub msg
port signupsPort : (Decode.Value -> msg) -> Sub msg
port rolePort : (Decode.Value -> msg) -> Sub msg
port boardPort : (Decode.Value -> msg) -> Sub msg

port tradeShapePort : Int -> Cmd msg
port playPort : Encode.Value -> Cmd msg

-- UPDATE

toDictionaryWithKey : (obj -> comparable) -> List obj -> Dict comparable obj
toDictionaryWithKey func list =
  List.map (\n -> (func n, n)) list |> Dict.fromList

setSelectedStoneId : Maybe Int -> Board -> Board
setSelectedStoneId id board =
  {board | selectedStoneId = id}

isCurrentlyPlaing : Board -> Int -> Bool
isCurrentlyPlaing board playerId =
  case board.currentPlayerId of
    Just currentPlayerId ->
      playerId == currentPlayerId
    Nothing ->
      False

canTouchStone : Model -> Stone -> Bool
canTouchStone model stone =
  case model.role of
    Player playerId ->
      if stone.playerId == playerId && isCurrentlyPlaing model.board playerId then
        True
      else
        False
    _ ->
      False

createPlayCommand : (Int, Int) -> (Int, Int) -> Cmd msg
createPlayCommand from to =
  Encode.object [
    ("from", Encode.object [
      ("x", Encode.int <| Tuple.first from),
      ("y", Encode.int <| Tuple.second from)
    ]),
    ("to", Encode.object [
      ("x", Encode.int <| Tuple.first to),
      ("y", Encode.int <| Tuple.second to)
    ])
  ] |> playPort

updateToPlayAt : Model -> Int -> (Int, Int) -> (Model, Cmd msg)
updateToPlayAt model selectedStoneId coords =
  let
    maybeSelectedStone = Dict.get selectedStoneId model.board.stones
  in
    case maybeSelectedStone of
      Just prevSelectedStone ->
        if canTouchStone model prevSelectedStone then
        (
          {model | board = model.board |> setSelectedStoneId (Nothing)},
          createPlayCommand prevSelectedStone.coords coords
        )
        else
          (model, Cmd.none)
      Nothing ->
        ({model | errorMessage = "Selected stone disappeared"}, Cmd.none)

calculateEarned : (List Shape) -> Int -> Int
calculateEarned shapes playerId =
  shapes |> List.filter (\shape -> shape.playerId == playerId && shape.traded) |> List.map .points |> List.sum

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    StateReceived result ->
      case result of
        Ok value ->
          ({model | state = value}, Cmd.none)
        Err errorMessage ->
          ({model | errorMessage = errorMessage}, Cmd.none)
    SignupsReceived result ->
      case result of
        Ok data ->
          ({model | signups = data |> toDictionaryWithKey .playerId }, Cmd.none)
        Err error ->
          ({model | errorMessage = Decode.errorToString error}, Cmd.none)
    RoleReceived result ->
      case result of
        Ok value ->
          ({model | role = value}, Cmd.none)
        Err errorMessage ->
          ({model | errorMessage = errorMessage}, Cmd.none)
    BoardReceived result ->
      case result of
        Ok data ->
          ({model | board = data}, Cmd.none)
        Err error ->
          ({model | errorMessage = Decode.errorToString error}, Cmd.none)
    StoneClicked stone ->
      case model.board.selectedStoneId of
        Just selectedStoneId ->
          updateToPlayAt model selectedStoneId stone.coords
        Nothing ->
          if canTouchStone model stone then
            ({model | board = model.board |> setSelectedStoneId (Just stone.id)}, Cmd.none)
          else
            (model, Cmd.none)
    FieldClicked coords ->
      case model.board.selectedStoneId of
        Just selectedStoneId ->
          updateToPlayAt model selectedStoneId coords
        Nothing ->
          (model, Cmd.none)
    TradeShape shape ->
      (model, tradeShapePort shape.id)

-- SUBSCRIPTIONS

parseStateString : String -> Result String State
parseStateString string =
  case string of
    "playing" ->
      Ok Playing
    "waiting" ->
      Ok Waiting
    "finished" ->
      Ok Finished
    _ ->
      Err "Invalid state string"

decodeRole : Decode.Value -> Result String Role
decodeRole data =
  case Decode.decodeValue (Decode.field "role" Decode.string) data of
    Ok stringRole ->
      case stringRole of
        "play" ->
          case Decode.decodeValue (Decode.field "player_id" Decode.int) data of
            Ok playerId ->
              Ok (Player playerId)
            Err error ->
              Err <| "failed to parse player ID"
        "spectate" ->
          Ok Spectator
        _ ->
          Err <| stringRole ++ " is not a valid role"
    Err error ->
      Err <| Decode.errorToString error

signupsDecoder : Decode.Decoder (List Signup)
signupsDecoder =
  Decode.list <| (Decode.succeed Signup
    |> DPipeline.required "user_name" Decode.string
    |> DPipeline.required "player_id" Decode.int
    |> DPipeline.required "spent_points" Decode.int
    |> DPipeline.required "color" Color.colorDecoder)

edgeDecoder : Decode.Decoder (List Edge)
edgeDecoder =
  (Decode.list stoneDecoder) |> Decode.andThen (
    \stones -> Decode.succeed <| stonesToEdges <| stones
  )

stonesToEdges : List Stone -> List Edge
stonesToEdges stones =
  stones |> List.concatMap (
    \{id, coords} ->
      let
        (x, y) = coords
      in
        List.concat [
          case stones |> (List.filter (\stone -> (Tuple.first stone.coords) == x + 1 && (Tuple.second stone.coords) == y)) |> List.head of
            Just foundStone -> []
            Nothing -> [Edge (x + 1, y) (x + 1, y + 1)]
          ,
          case stones |> (List.filter (\stone -> (Tuple.first stone.coords) == x && (Tuple.second stone.coords) == y + 1)) |> List.head of
            Just foundStone -> []
            Nothing -> [Edge (x, y + 1) (x + 1, y + 1)]
          ,
          case stones |> (List.filter (\stone -> (Tuple.first stone.coords) == x - 1 && (Tuple.second stone.coords) == y)) |> List.head of
            Just foundStone -> []
            Nothing -> [Edge (x, y) (x, y + 1)]
          ,
          case stones |> (List.filter (\stone -> (Tuple.first stone.coords) == x && (Tuple.second stone.coords) == y - 1)) |> List.head of
            Just foundStone -> []
            Nothing -> [Edge (x, y) (x + 1, y )]
        ]
  )

vertexDecoder : Decode.Decoder (Set (Int, Int))
vertexDecoder =
  (Decode.list stoneDecoder) |> Decode.andThen (
    \stones -> Decode.succeed <| stonesToVertices <| stones
  )

stonesToVertices : List Stone -> Set (Int, Int)
stonesToVertices stones =
  stones |> stonesToEdges |> List.concatMap (
    \edge ->
      [
        (Tuple.first edge.from, Tuple.second edge.from),
        (Tuple.first edge.to, Tuple.second edge.to)
      ]
  ) |> Set.fromList

coordsDecoder : Decode.Decoder (Int, Int)
coordsDecoder =
  Decode.succeed Tuple.pair
    |> DPipeline.required "x" Decode.int
    |> DPipeline.required "y" Decode.int

stoneDecoder : Decode.Decoder Stone
stoneDecoder =
  Decode.succeed Stone 
    |> DPipeline.required "id" Decode.int
    |> DPipeline.custom coordsDecoder
    |> DPipeline.required "player_id" Decode.int

shapesDecoder : Decode.Decoder (List Shape)
shapesDecoder =
  Decode.andThen (\shapes -> Decode.succeed (List.sortBy .points shapes)) <| Decode.list <| (Decode.succeed Shape 
    |> DPipeline.required "id" Decode.int
    |> DPipeline.required "player_id" Decode.int
    |> DPipeline.required "color" Color.colorDecoder
    |> DPipeline.required "name" Decode.string
    |> DPipeline.required "points" Decode.int
    |> DPipeline.required "traded" Decode.bool
    |> DPipeline.requiredAt [ "board_data", "stones" ] (Decode.list stoneDecoder)
    |> DPipeline.requiredAt [ "board_data", "stones" ] edgeDecoder
    |> DPipeline.requiredAt [ "board_data", "stones" ] vertexDecoder)

boardDecoder : Decode.Decoder Board
boardDecoder =
  Decode.succeed Board
    |> DPipeline.requiredAt [ "board_data", "width" ] Decode.int
    |> DPipeline.requiredAt [ "board_data", "height" ] Decode.int
    |> DPipeline.requiredAt [ "board_data", "stones" ] (Decode.list stoneDecoder |> Decode.andThen (\list -> List.map (\n -> (n.id, n)) list |> Dict.fromList |> Decode.succeed))
    |> DPipeline.required "fulfilled_shapes" shapesDecoder
    |> DPipeline.hardcoded Nothing
    |> DPipeline.required "currently_playing" (Decode.nullable Decode.int)

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.batch [
    statePort (parseStateString >> StateReceived), -- function composure
    signupsPort ((Decode.decodeValue signupsDecoder) >> SignupsReceived), -- decoding a json
    rolePort (decodeRole >> RoleReceived),
    boardPort ((Decode.decodeValue boardDecoder) >> BoardReceived)
  ]

-- MAIN

main : Program Flags Model Message
main =
  Browser.element
    {
      init = init,
      view = view >> Html.Styled.toUnstyled,
      update = update,
      subscriptions = subscriptions
    }
