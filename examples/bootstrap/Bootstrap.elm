module Bootstrap exposing (main)

import Date exposing (Date, Day(..), day, dayOfWeek, month, year)
import DatePicker exposing (defaultSettings, DateEvent(..))
import Html exposing (Html, div, form, h1, input, label, text)
import Html.Attributes exposing (class, type_, value)


type Msg
    = ToDatePicker DatePicker.Msg


type alias Model =
    { date : Maybe Date
    , datePicker : DatePicker.DatePicker
    }


settings : DatePicker.Settings
settings =
    let
        isDisabled date =
            dayOfWeek date
                |> flip List.member [ Sat, Sun ]
    in
        { defaultSettings
            | isDisabled = isDisabled
            , inputClassList = [ ( "form-control", True ) ]
            , inputName = Just "date"
            , inputId = Just "date-field"
        }


init : ( Model, Cmd Msg )
init =
    let
        ( datePicker, datePickerFx ) =
            DatePicker.init
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
                ( newDatePicker, datePickerFx, event ) =
                    DatePicker.update settings msg datePicker
            in
                { model
                    | date =
                        case event of
                            Changed date ->
                                date

                            NoChange ->
                                model.date
                    , datePicker = newDatePicker
                }
                    ! [ Cmd.map ToDatePicker datePickerFx ]


view : Model -> Html Msg
view ({ date, datePicker } as model) =
    div [ class "col-md-3" ]
        [ form []
            [ div [ class "form-group" ]
                [ label [] [ text "Pick a date" ]
                , DatePicker.view date settings datePicker
                    |> Html.map ToDatePicker
                ]
            , input
                [ type_ "submit"
                , class "btn btn-primary"
                , value "Submit"
                ]
                []
            ]
        ]


formatDate : Date -> String
formatDate d =
    toString (month d) ++ " " ++ toString (day d) ++ ", " ++ toString (year d)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
