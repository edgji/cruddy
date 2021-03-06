# View that displays a form for an entity instance
class Cruddy.Entity.Form extends Cruddy.Layout.Layout
    className: "entity-form"

    events:
        "click .btn-save": "save"
        "click .btn-close": "close"
        "click .btn-destroy": "destroy"
        "click .btn-copy": "copy"
        "click .btn-refresh": "refresh"

    constructor: (options) ->
        @className += " " + @className + "-" + options.model.entity.id

        super

    initialize: (options) ->
        super

        @inner = options.inner ? no

        @listenTo @model, "destroy", @handleDestroy
        @listenTo @model, "invalid", @displayInvalid
        @listenTo @model, "change",  @handleChange

        @listenTo model, "change",  @handleChange for key, model of @model.related

        @hotkeys = $(document).on "keydown." + @cid, "body", $.proxy this, "hotkeys"

        $(window).on "beforeunload.#{ @cid }", => @confirmationMessage(yes)

        return this

    setupDefaultLayout: ->
        tab = @append new Cruddy.Layout.TabPane { title: @model.entity.get("title").singular }, this

        tab.append new Cruddy.Layout.Field { field: field.id }, tab for field in @entity.fields.models

        return this

    hotkeys: (e) ->
        # Ctrl + Z
        if e.ctrlKey and e.keyCode is 90 and e.target is document.body
            @model.set @model.previousAttributes()
            return false

        # Ctrl + Enter
        if e.ctrlKey and e.keyCode is 13
            @save()
            return false

        # Escape
        if e.keyCode is 27
            @close()
            return false

        this

    handleChange: ->
        # @$el.toggleClass "dirty", @model.hasChangedSinceSync()

        this

    displayAlert: (message, type, timeout) ->
        @alert.remove() if @alert?

        @alert = new Alert
            message: message
            className: "flash"
            type: type
            timeout: timeout

        @footer.prepend @alert.render().el

        this

    displaySuccess: -> @displayAlert Cruddy.lang.success, "success", 3000

    displayInvalid: -> @displayAlert Cruddy.lang.invalid, "warning", 5000

    displayError: (xhr) -> @displayAlert Cruddy.lang.failure, "danger", 5000 unless xhr.responseJSON?.error is "VALIDATION"

    handleDestroy: ->
        if @model.entity.get "soft_deleting"
            @update()
        else
            if @inner then @remove() else Cruddy.router.navigate @model.entity.link(), trigger: true

        this

    show: ->
        @$el.toggleClass "opened", true

        @items[0].activate()

        @focus()

        this

    refresh: ->
        @model.fetch() if @confirmClose()

        return this

    save: ->
        return if @request?

        @request = @model.save null,
            displayLoading: yes

            xhr: =>
                xhr = $.ajaxSettings.xhr()
                xhr.upload.addEventListener('progress', $.proxy @, "progressCallback") if xhr.upload

                xhr

        @request.done($.proxy this, "displaySuccess").fail($.proxy this, "displayError")

        @request.always =>
            @request = null
            @progressBar.parent().hide()
            @update()

        @update()

        this

    progressCallback: (e) ->
        if e.lengthComputable
            width = (e.loaded * 100) / e.total

            @progressBar.width(width + '%').parent().show()

        this

    close: ->
        if @confirmClose()
            @remove()
            @trigger "close"

        this

    confirmClose: -> not (message = @confirmationMessage()) or confirm message

    confirmationMessage: (closing) ->
        return (if closing then Cruddy.lang.onclose_abort else Cruddy.lang.confirm_abort) if @request

        return (if closing then Cruddy.lang.onclose_discard else Cruddy.lang.confirm_discard) if @model.hasChangedSinceSync()

    destroy: ->
        return if @request or @model.isNew()

        softDeleting = @model.entity.get "soft_deleting"

        confirmed = if not softDeleting then confirm(Cruddy.lang.confirm_delete) else yes

        if confirmed
            @request = if @softDeleting and @model.get "deleted_at" then @model.restore else @model.destroy wait: true

            @request.always => @request = null

        this

    copy: ->
        Cruddy.app.page.display @model.copy()

        this

    render: ->
        @$el.html @template()

        @$container = @$component "body"

        @nav = @$component "nav"
        @footer = @$ "footer"
        @submit = @$ ".btn-save"
        @destroy = @$ ".btn-destroy"
        @copy = @$ ".btn-copy"
        @$refresh = @$ ".btn-refresh"
        @progressBar = @$ ".form-save-progress"

        @update()

        super

    renderElement: (el) ->
        @nav.append el.getHeader().render().$el

        super

    update: ->
        permit = @model.entity.getPermissions()
        isNew = @model.isNew()

        @$el.toggleClass "loading", @request?

        @submit.text if isNew then Cruddy.lang.create else Cruddy.lang.save
        @submit.attr "disabled", @request?
        @submit.toggle if isNew then permit.create else permit.update

        @destroy.attr "disabled", @request?
        @destroy.toggle not isNew and permit.delete

        @copy.toggle not isNew and permit.create
        @$refresh.toggle not isNew

        @external?.remove()

        @$refresh.after @external = $ @externalLinkTemplate @model.extra.external if @model.extra.external

        this

    template: ->
        """
        <div class="navbar navbar-default navbar-static-top" role="navigation">
            <div class="container-fluid">
                <ul id="#{ @componentId "nav" }" class="nav navbar-nav"></ul>
            </div>
        </div>

        <div class="tab-content" id="#{ @componentId "body" }"></div>

        <footer>
            <div class="pull-left">
                <button type="button" class="btn btn-link btn-destroy" title="#{ Cruddy.lang.model_delete }">
                    <span class="glyphicon glyphicon-trash"></span>
                </button>

                <button type="button" tabindex="-1" class="btn btn-link btn-copy" title="#{ Cruddy.lang.model_copy }">
                    <span class="glyphicon glyphicon-book"></span>
                </button>

                <button type="button" class="btn btn-link btn-refresh" title="#{ Cruddy.lang.model_refresh }">
                    <span class="glyphicon glyphicon-refresh"></span>
                </button>
            </div>

            <button type="button" class="btn btn-default btn-close">#{ Cruddy.lang.close }</button>
            <button type="button" class="btn btn-primary btn-save"></button>

            <div class="progress"><div class="progress-bar form-save-progress"></div></div>
        </footer>
        """

    externalLinkTemplate: (href) -> """
        <a href="#{ href }" class="btn btn-link" title="#{ Cruddy.lang.view_external }" target="_blank">
            #{ b_icon "eye-open" }
        </a>
        """

    remove: ->
        @trigger "remove", @

        @request.abort() if @request

        @$el.one(TRANSITIONEND, =>
            $(document).off "." + @cid
            $(window).off "." + @cid

            @trigger "removed", @

            super
        )
        .removeClass "opened"

        super