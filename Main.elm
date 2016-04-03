module Main where

import Task exposing (Task, andThen)
import SocketIO
import Json.Decode as Json exposing ((:=))
import Result
import Html exposing (Html, Attribute, text, div, table, thead, tbody, th, tr, td)
import Html.Attributes exposing (id, style)
import Dict exposing (Dict)
import Date
import Date.Format

-- MAIN

main : Signal Html
main =
  Signal.map view modelSignal

modelSignal : Signal Model
modelSignal =
  Signal.foldp update initModel mainSignal

mainSignal : Signal Action
mainSignal =
  Signal.mergeMany
    [ readingsActions
    ]

-- MODEL

initModel : Model
initModel = Model (Dict.fromList [])

type alias Model =
  { readings : Dict String Reading
  }

type alias Reading =
  { id : String
  , latitude : Float
  , longitude : Float
  , courseDeg : Float
  , altitude : Int
  , speed : Float
  , timestamp : Int
  }

-- SOCKET

port socketHost : String

socket : Task x SocketIO.Socket
socket = SocketIO.io ("http://" ++ socketHost ++ ":8001") SocketIO.defaultOptions

eventName : String
eventName = "reading"

port readingsSocket : Task x ()
port readingsSocket = socket `andThen` SocketIO.on eventName received.address

received : Signal.Mailbox String
received = Signal.mailbox "null"

readingDecoder : Json.Decoder Reading
readingDecoder =
  Json.object7 Reading
    ("id" := Json.string)
    ("latitude" := Json.float)
    ("longitude" := Json.float)
    ("courseDeg" := Json.float)
    ("altitude" := Json.int)
    ("speed" := Json.float)
    ("timestamp" := Json.int)

readingsActions : Signal Action
readingsActions =
  let
    handleResult result =
      case result of
        Ok reading -> AddReading reading
        Err _ -> NoOp
  in
    Signal.map
      (Json.decodeString readingDecoder >> handleResult)
      received.signal

port outgoingReadings : Signal (List Reading)
port outgoingReadings =
  Signal.map allReadings modelSignal

-- HELPERS

allReadings : Model -> List Reading
allReadings =
  .readings >> Dict.values


-- UPDATE

type Action
    = AddReading Reading
    | NoOp

update : Action -> Model -> Model
update action model =
  case action of
    AddReading reading ->
      if Dict.member reading.id model.readings then
        model
      else
        { model | readings = Dict.insert reading.id reading model.readings }
    NoOp ->
      model

-- VIEW

view : Model -> Html
view model =
  div []
    [ div [ id "map", mapStyle ] []
    , table []
      [ thead []
        [ th [] [ text "Latitude" ]
        , th [] [ text "Longitude" ]
        , th [] [ text "Course (°)" ]
        , th [] [ text "Altitude (m)" ]
        , th [] [ text "Speed (km/h)" ]
        , th [] [ text "Timestamp" ]
        ]
      , tbody [] ((allReadings >> List.sortBy .timestamp >> List.reverse >> List.map tableRow) model)
      ]
    ]

toText : a -> Html
toText =
  toString >> text

formatTimestamp : Int -> Html
formatTimestamp =
  (*) 1000 >> toFloat >> Date.fromTime >> Date.Format.format "%Y-%m-%d %l:%M:%S %p" >> text

tableRow : Reading -> Html
tableRow reading =
  tr []
  [ td [] [ toText reading.latitude ]
  , td [] [ toText reading.longitude ]
  , td [] [ toText reading.courseDeg ]
  , td [] [ toText reading.altitude ]
  , td [] [ toText reading.speed ]
  , td [] [ formatTimestamp reading.timestamp ]
  ]

mapStyle : Attribute
mapStyle =
  style
    [ ("height", "400px")
    ]
