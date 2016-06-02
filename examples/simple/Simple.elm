module Simple exposing (main)

import Date exposing (Date, Day(..), day, dayOfWeek, month, year)
import DatePicker exposing (defaultSettings)
import Html exposing (Html, div, h1, text)
import Html.App as Html


type Msg
    = ToDatePicker DatePicker.Msg


type alias Model =
    { date : Maybe Date
    , datePicker : DatePicker.DatePicker
    }


init : ( Model, Cmd Msg )
init =
    let
        isDisabled date =
            dayOfWeek date `List.member` [ Sat, Sun ]

        ( datePicker, datePickerFx ) =
            DatePicker.init { defaultSettings | isDisabled = isDisabled }
    in
        { date = Nothing
        , datePicker = datePicker
        }
            ! [ Cmd.map ToDatePicker datePickerFx ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ datePicker } as model) =
    case msg of
        ToDatePicker msg ->
            let
                ( datePicker, datePickerFx, mDate ) =
                    DatePicker.update msg datePicker

                date =
                    case mDate of
                        Nothing ->
                            model.date

                        date ->
                            date
            in
                { model
                    | date = date
                    , datePicker = datePicker
                }
                    ! [ Cmd.map ToDatePicker datePickerFx ]


view : Model -> Html Msg
view ({ date, datePicker } as model) =
    div []
        [ case date of
            Nothing ->
                h1 [] [ text "Pick a date" ]

            Just date ->
                h1 [] [ text <| formatDate date ]
        , DatePicker.view datePicker
            |> Html.map ToDatePicker
        ]


formatDate : Date -> String
formatDate d =
    toString (month d) ++ " " ++ toString (day d) ++ ", " ++ toString (year d)


main : Program Never
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
