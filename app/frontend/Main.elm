port module Main exposing (..)

import Color

import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as DPipeline

import Browser
import Dict exposing (Dict)
import Css
import Debug
import Css.Transitions
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attributes
import Html.Styled.Events as Events
import Html
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
    x : Int,
    y : Int,
    playerId : Int
  }

type alias Shape =
  {
    id : Int,
    playerId : Int,
    name : String,
    points : Int,
    traded : Bool,
    stones : List Stone
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

renderGridElements : Int -> Int -> BoardParameters -> List (Svg.Styled.Svg Message)
renderGridElements x y params =
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
  ++ (createCoordinateTuples (x + 1) (y + 1) |> List.map (
    \coords -> Svg.Styled.circle
    [
      Svg.Styled.Attributes.r "4.3",
      Svg.Styled.Attributes.cx <| String.fromFloat (toFloat (Tuple.first coords) * params.unit + params.offset - 2),
      Svg.Styled.Attributes.cy <| String.fromFloat (toFloat (Tuple.second coords) * params.unit + params.offset - 2),
      Svg.Styled.Attributes.css [
        Css.fill <| Css.rgb 255 255 255
      ]
    ] []
  ))


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

renderStones : (List Stone) -> Maybe Int -> BoardParameters -> List (Svg.Styled.Svg Message)
renderStones stones selectedStoneId params =
  let
    offset = 23
    radius = 20
  in
    stones |> List.map (
      \stone ->
        Svg.Styled.circle
        [
          Svg.Styled.Attributes.r <| String.fromInt radius,
          Svg.Styled.Attributes.transform <| (
            "translate("
            ++ String.fromFloat (toFloat stone.x * params.unit + offset + params.offset)
            ++ ","
            ++ String.fromFloat (toFloat stone.y * params.unit + offset + params.offset)
            ++ ")"
          ),
          Svg.Styled.Attributes.fill <| "url(#" ++ (getGradientIdentifier stone.playerId (isStoneSelected stone selectedStoneId))++ ")",
          Svg.Styled.Attributes.css [
            Css.Transitions.transition [
              Css.Transitions.transform3 1000 0 Css.Transitions.easeInOut
            ]
          ],
          Svg.Styled.Events.onClick (StoneClicked stone)
        ] []
    )

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

renderBoard : Board -> (Dict Int Signup) -> Html Message
renderBoard board signups =
  let
    params = BoardParameters
      50
      7
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
      (renderGridElements board.x board.y params)
      ++ (renderStones (board.stones |> Dict.values) board.selectedStoneId params)
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

view : Model -> Html Message
view model =
  case model.errorMessage of
    "" ->
      let
        maybeCurrentSignup = getCurrentSignup model
        maybeOtherSignup = getOtherSignup model
        playerStyle = \current signup -> [
          Css.property "text-align" "center",
          Css.property "font-size" (if current then "3.6rem" else "2.2rem"),
          Css.property "font-family" "futuraMediumBT",
          Css.displayFlex,
          Css.property "align-items" "center",
          Css.property "justify-content" "space-around",
          Css.textShadow4 (Css.px 0) (Css.px 0) (Css.rem 0.3) (Color.toCssColor signup.color),
          Css.height (Css.rem 6),
          Css.color (Css.rgb 255 255 255)]
        bottomButtonStyle = Attributes.css [
          Css.property "font-family" "futuraMediumBT",
          Css.color (Css.rgb 255 255 255),
          Css.fontSize (Css.rem 2),
          Css.backgroundColor (Css.rgba 0 0 0 0),
          Css.property "border" "none"]
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
                  div [
                    Attributes.css (
                      playerStyle (otherSignup.playerId |> isCurrentlyPlaing model.board) otherSignup
                      ++ [
                        Css.marginTop (Css.rem 1.5)
                      ]
                    )
                  ]
                    [
                      span [] [
                        otherSignup.userName ++ ": " ++ String.fromInt(calculateEarned model.board.shapes otherSignup.playerId - otherSignup.spentPoints) |> text ]
                    ]
                  ,
                  renderBoard model.board model.signups,
                  div [ Attributes.css 
                    ((playerStyle (currentSignup.playerId |> isCurrentlyPlaing model.board) currentSignup)
                    ++ [
                      Css.paddingLeft (Css.rem 1),
                      Css.paddingRight (Css.rem 1)
                    ] )
                  ]
                    [ 
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
                      ,
                      span [] [
                        currentSignup.userName ++ ": " ++ String.fromInt(calculateEarned model.board.shapes currentSignup.playerId - currentSignup.spentPoints) |> text 
                      ],
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
                    ]
                  ,
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

-- PORTS
port statePort : (String -> msg) -> Sub msg
port signupsPort : (Decode.Value -> msg) -> Sub msg
port rolePort : (Decode.Value -> msg) -> Sub msg
port boardPort : (Decode.Value -> msg) -> Sub msg

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
          createPlayCommand (prevSelectedStone.x, prevSelectedStone.y) coords
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
          updateToPlayAt model selectedStoneId (stone.x, stone.y)
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

stoneDecoder : Decode.Decoder Stone
stoneDecoder =
  Decode.succeed Stone 
    |> DPipeline.required "id" Decode.int
    |> DPipeline.required "x" Decode.int
    |> DPipeline.required "y" Decode.int
    |> DPipeline.required "player_id" Decode.int

shapesDecoder : Decode.Decoder (List Shape)
shapesDecoder =
  Decode.list <| (Decode.succeed Shape 
    |> DPipeline.required "id" Decode.int
    |> DPipeline.required "player_id" Decode.int
    |> DPipeline.required "name" Decode.string
    |> DPipeline.required "points" Decode.int
    |> DPipeline.required "traded" Decode.bool
    |> DPipeline.requiredAt [ "board_data", "stones" ] (Decode.list stoneDecoder))

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
