# elm-datepicker

``` shell
elm package install elm-community/elm-datepicker
```

A reusable date picker component in Elm.


## Usage

The `DatePicker.init` method initialises the DatePicker. It takes a single `settings` argument.
The `DatePicker.defaultSettings` is provided to make it easier to use. You only have to override the
settings that you are interested in.

The `DatePicker.init` method returns the initialised DatePicker and associated `Cmds` so it must
be done in your program's `init` or `update` methods:

```elm
        ( datePicker, datePickerCmd ) =
            DatePicker.init
                { defaultSettings
                    | inputClassList = [ ( "form-control", True ) ]
                    , inputId = Just "datepicker"
                }

```

The `DatePicker` can be displayed in a view using the `DatePicker.view` function. It returns its own
message type so you should wrap it in one of your own messages using `Html.map`:


```elm
type Msg
    = ...
    | SetDatePicker DatePicker.Msg
    | ...


view : Model -> Html Msg
view model =
    ...
    div [] [
        DatePicker.view model.startDatePicker |> Html.map SetDatePicker
        ]

```

In order handle `Msg` in your update function, you should unwrap the `DatePicker.Msg` and pass it
down to the `DatePicker.update` function. The `DatePicker.update` function returns the new date as
third value in the return tuple if the date as changed. As it might not have changed it is returned
as a `Maybe Date` where `Nothing` indicates no change.

```elm
update : Msg -> Model -> ( Model, Cmd, Msg )
update msg model =
    case msg of
        ...

         SetDatePicker msg ->
            let
                ( newDatePicker, datePickerCmd, maybeNewDate ) =
                    DatePicker.update msg model.startDatePicker

                date =
                    case maybeNewDate of
                        Nothing ->
                            model.date

                        Just newDate ->
                            newDate |> processDate
            in
                { model
                    | date = date
                    , datePicker = newDatePicker
                }
                    ! [ Cmd.map SetDatePicker datePickerCmd ]

```

If you have a `DatePicker` and you would like to change the date before displaying it, you can use
the `DatePicker.init` function to replace it with a new `DatePicker` with the new date in your
`update` function:

```elm

update msg model =
    case msg of
        ...

        NewForm date ->
            let
                ( datePicker, datePickerCmd ) =
                    let
                        settings =
                            { defaultSettings
                                | pickedDate = Just date
                                , inputClassList = [ ( "form-control", True ) ]
                                , inputId = Just "datepicker"
                            }
                    in
                        DatePicker.init settings

             in
                { model
                    | datePicker = datePicker
                }
                    ! [ Cmd.map SetDatePicker datePickerCmd
                      ]
```



## Examples

See the [examples][examples] folder or try it on ellie-app: [simple] example and [bootstrap] example.

[examples]: https://github.com/elm-community/elm-datepicker/tree/master/examples
[simple]: https://ellie-app.com/pwFvvCqBgYa1/0
[bootstrap]: https://ellie-app.com/pwGJj5T6TBa1/0


## CSS

The CSS for the date picker is distributed separately.  You can grab
the compiled CSS from [here][compiled] or you can grab the SCSS source
from [here][scss].

[compiled]: https://github.com/elm-community/elm-datepicker/blob/master/css/elm-datepicker.css
[scss]: https://github.com/elm-community/elm-datepicker/blob/master/css/elm-datepicker.scss
