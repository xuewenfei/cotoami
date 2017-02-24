module Components.Timeline.View exposing (..)

import Html exposing (..)
import Html.Keyed
import Html.Attributes exposing (..)
import Html.Events
import Html.Events exposing 
    (on, onWithOptions, onClick, onMouseDown, onFocus, onBlur, onInput, keyCode)
import Json.Decode as Decode
import Markdown
import Markdown.Config exposing (defaultElements, defaultOptions)
import Exts.Maybe exposing (isJust, isNothing)
import Utils exposing (isBlank)
import App.Types exposing (Session, Cotonoma)
import App.Markdown exposing (markdownOptions, markdownElements)
import Components.Timeline.Model exposing (Post, Model, isPostedInCotonoma)
import Components.Timeline.Messages exposing (..)


view : Model -> Maybe Session -> Maybe Cotonoma -> Maybe Int -> Html Msg
view model maybeSession maybeCotonoma activeCotoId =
    div [ id "input-and-timeline", class (timelineClass model) ]
        [ timelineDiv model maybeSession maybeCotonoma activeCotoId
        , div [ id "new-coto" ]
            [ div [ class "toolbar", hidden (not model.editingNew) ]
                [ (case maybeSession of
                      Nothing -> 
                          span [ class "user anonymous" ]
                              [ i [ class "material-icons" ] [ text "perm_identity" ]
                              , text "Anonymous"
                              ]
                      Just session -> 
                          span [ class "user session" ]
                              [ img [ class "avatar", src session.avatarUrl ] []
                              , span [ class "name" ] [ text session.displayName ]
                              ]
                  )
                , div [ class "tool-buttons" ]
                    [ button 
                        [ class "button-primary"
                        , disabled (isBlank model.newContent)
                        , onMouseDown Components.Timeline.Messages.Post 
                        ]
                        [ text "Post"
                        , span [ class "shortcut-help" ] [ text "(Ctrl + Enter)" ]
                        ]
                    ]
                ]
            , textarea
                [ class "coto"
                , placeholder "Write your idea in Markdown"
                , value model.newContent
                , onFocus EditorFocus
                , onBlur EditorBlur
                , onInput EditorInput
                , onKeyDown EditorKeyDown
                ]
                []
            ]
        ]


timelineDiv : Model -> Maybe Session -> Maybe Cotonoma -> Maybe Int -> Html Msg
timelineDiv model maybeSession maybeCotonoma activeCotoId =
    Html.Keyed.node
        "div"
        [ id "timeline", classList [ ( "loading", model.loading ) ] ]
        (List.map 
            (\post -> 
                ( getKey post
                , postDiv maybeSession maybeCotonoma activeCotoId post
                )
            ) 
            (List.reverse model.posts)
        )


getKey : Post -> String
getKey post =
    case post.cotoId of
        Just cotoId -> toString cotoId
        Nothing -> 
            case post.postId of
                Just postId -> toString postId
                Nothing -> ""
    
    
postDiv : Maybe Session -> Maybe Cotonoma -> Maybe Int -> Post -> Html Msg
postDiv maybeSession maybeCotonoma activeCotoId post =
    let
        postedInAnother = not (isPostedInCotonoma maybeCotonoma post)
    in
        div
            [ classList 
                [ ( "coto", True )
                , ( "active", isActive post activeCotoId )
                , ( "posting", (isJust maybeSession) && (isNothing post.cotoId) )
                , ( "being-hidden", post.beingDeleted )
                , ( "posted-in-another-cotonoma", postedInAnother )
                ]
            , (case post.cotoId of
                Nothing -> onClick NoOp
                Just cotoId -> onClick (PostClick cotoId)
              )
            ] 
            [ div [ class "border" ] []
            ,  (case post.cotoId of
                Nothing -> span [] []
                Just cotoId ->
                    a 
                        [ class "open-coto"
                        , title "Open coto view"
                        , onClickWithoutPropagation (PostOpen post)
                        ] 
                        [ i [ class "material-icons" ] [ text "open_in_new" ] ]
              )
            , (case post.postedIn of
                Nothing -> span [] []
                Just postedIn ->
                    if postedInAnother then
                        a 
                            [ class "posted-in"
                            , onClickWithoutPropagation (CotonomaClick postedIn.key) 
                            ] 
                            [ text postedIn.name ]
                    else
                        span [] []
              )
            , contentDiv post
            ]
        

isActive : Post -> Maybe Int -> Bool
isActive post activeCotoId =
    case post.cotoId of
        Nothing -> False
        Just cotoId -> (Maybe.withDefault -1 activeCotoId) == cotoId
    
    
contentDiv : Post -> Html Msg
contentDiv post =
    if post.asCotonoma then
        div [ class "coto-as-cotonoma" ]
            [ a [ onClickWithoutPropagation (CotonomaClick post.cotonomaKey) ]
                [ i [ class "material-icons" ] [ text "exit_to_app" ]
                , span [ class "cotonoma-name" ] [ text post.content ]
                ]
            ]
    else 
        markdown post.content 
        
        
markdown : String -> Html Msg
markdown content =
    div [ class "content" ]
        <| Markdown.customHtml 
            markdownOptions
            { markdownElements
            | image = customImageElement
            }
            content


customImageElement : Markdown.Config.Image -> Html Msg
customImageElement image =
    img
        [ src image.src
        , alt image.alt
        , title (Maybe.withDefault "" image.title)
        , onLoad ImageLoaded
        ]
        []
  

timelineClass : Model -> String
timelineClass model =
    if model.editingNew then
        "editing"
    else
        ""


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)


onLoad : msg -> Attribute msg
onLoad message =
    on "load" (Decode.succeed message)
  

onClickWithoutPropagation : msg -> Attribute msg
onClickWithoutPropagation message =
    let
        defaultOptions = Html.Events.defaultOptions
    in
        onWithOptions 
            "click"
            { defaultOptions | stopPropagation = True }
            (Decode.succeed message)
  
  