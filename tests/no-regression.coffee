fs = require "fs"
path = require 'path'
should = require 'should'
async = require 'async'
http = require 'http'

Client = require("request-json").JsonClient
# Schema = require('jugglingdb').Schema
adapter = require('../src/index')

client = new Client "http://localhost:9101/"
client.setBasicAuth "test", "apptoken"

TESTFILENAME = 'test.png'
TESTFILE = path.join __dirname, TESTFILENAME
TESTFILEOUT = path.join __dirname, 'test-get.png'

Note = adapter.getModel 'Note',
    title:
        type: String
    content:
        type: String
    author:
        type: String

# everything below this is left untouched from jugglingdb-cozy-adapter tests
# CHANGES summary
#  - removed updateOrCreate
#  - removed createMany
#  - prevent creating a doc with a given id

describe "Existence", ->

    before (done) ->
        client.del "data/321/", (error, response, body) ->
            data =
                value: "created value"
                docType: "Note"
            client.post 'data/321/', data, (error, response, body) ->
                done()

    after (done) ->
        client.del "data/321/", (error, response, body) ->
            done()


    describe "Check Existence of a Document that does not exist in database", ->

        it "When I check existence of Document with id 123", \
                (done) ->
            Note.exists 123, (err, isExist) =>
                should.not.exist err
                @isExist = isExist
                done()

        it "Then false should be returned", ->
            @isExist.should.not.be.ok

    describe "Check Existence of a Document that does exist in database", ->

        it "When I check existence of Document with id 321", \
                (done) ->
            Note.exists 321, (err, isExist) =>
                should.not.exist err
                @isExist = isExist
                done()

        it "Then true should be returned", ->
            @isExist.should.be.ok


describe "Find", ->

    before (done) ->
        client.post 'data/321/',
            title: "my note"
            content: "my content"
            docType: "Note"
            , (error, response, body) ->
                done()

    after (done) ->
        client.del "data/321/", (error, response, body) ->
            done()


    describe "Find a note that does not exist in database", ->

        it "When I claim note with id 123", (done) ->
            Note.find 123, (err, note) =>
                @note = note
                done()

        it "Then null should be returned", ->
            should.not.exist @note

    describe "Find a note that does exist in database", ->

        it "When I claim note with id 321", (done) ->
            Note.find 321, (err, note) =>
                @note = note
                done()

        it "Then I should retrieve my note ", ->
            should.exist @note
            @note.title.should.equal "my note"
            @note.content.should.equal "my content"


describe "Create", ->

    before (done) ->
        client.post 'data/321/', {
            title: "my note"
            content: "my content"
            docType: "Note"
            } , (error, response, body) ->
                done()

    after (done) ->
        client.del "data/321/", (error, response, body) ->
            client.del "data/987/", (error, response, body) ->
                done()

    describe "Try to create a Document existing in Database", ->
        after ->
            @err = null
            @note = null

        it "When create a document with id 321", (done) ->
            Note.create { id: "321", "content":"created value"}, \
                    (err, note) =>
                @err = err
                @note = note
                done()

        it "Then an error is returned", ->
            should.exist @err

    # CHANGE : trow when creating a doc with a fixed id

    # describe "Create a new Document with a given id", ->

    #     before ->
    #         @id = "987"

    #     after ->
    #         @err = null
    #         @note = null

    #     it "When I create a document with id 987", (done) ->
    #         Note.create { id: @id, "content": "new note" }, (err, note) =>
    #             @err = err
    #             @note = note
    #             done()

    #     it "Then this should be set on document", ->
    #         should.not.exist @err
    #         should.exist @note
    #         @note.id.should.equal @id

    #     it "And the Document with id 987 should exist in Database", (done) ->
    #         Note.exists  @id, (err, isExist) =>
    #             should.not.exist err
    #             isExist.should.be.ok
    #             done()

    #     it "And the Document in DB should equal the sent Document", (done) ->
    #         Note.find  @id, (err, note) =>
    #             should.not.exist err
    #             note.id.should.equal @id
    #             note.content.should.equal "new note"
    #             done()


    describe "Create a new Document without an id", ->

        before ->
            @id = null

        after (done) ->
            @note.destroy =>
                @err = null
                @note = null
                done()

        it "When I create a document without an id", (done) ->
            Note.create { "title": "cool note", "content": "new note" }, \
                    (err, note) =>
                @err = err if err
                @note = note
                done()

        it "Then the id of the new Document should be returned", ->
            should.not.exist @err
            should.exist @note.id
            @id = @note.id

        it "And the Document should exist in Database", (done) ->
            Note.exists  @id, (err, isExist) =>
                should.not.exist err
                isExist.should.be.ok
                done()

        it "And the Document in DB should equal the sent Document", (done) ->
            Note.find  @id, (err, note) =>
                should.not.exist err
                note.id.should.equal @id
                note.content.should.equal "new note"
                done()


    # CHANGE: createMany removed (not used in any cozy repo)

    # describe "Create a many documents without an id", ->

    #     before ->
    #         @ids = []

    #     after (done) ->
    #         @note1.destroy =>
    #             @note2.destroy =>
    #                 @note3.destroy =>
    #                     done()

    #     it "When I create a document without an id", (done) ->
    #         dataList = [
    #             { "title": "cool note many 01", "content": "new note 01" }
    #             { "title": "cool note many 02", "content": "new note 02" }
    #             { "title": "cool note many 03", "content": "new note 03" }
    #         ]
    #         Note.createMany dataList, (err, ids) =>
    #             @err = err if err
    #             @ids = ids
    #             done()

    #     it "Then the ids of the new documents should be returned", ->
    #         should.not.exist @err
    #         should.exist @ids
    #         @ids.length.should.equal 3

    #     it "And the Document should exist in Database", (done) ->
    #         Note.exists @ids[0], (err, isExist) =>
    #             should.not.exist err
    #             isExist.should.be.ok
    #             Note.exists @ids[1], (err, isExist) =>
    #                 should.not.exist err
    #                 isExist.should.be.ok
    #                 Note.exists @ids[2], (err, isExist) =>
    #                     should.not.exist err
    #                     isExist.should.be.ok
    #                     done()

    #     it "And the documents in DB should equal the sent document", (done) ->
    #         Note.find @ids[0], (err, note) =>
    #             should.not.exist err
    #             note.id.should.equal @ids[0]
    #             note.content.should.equal "new note 01"
    #             @note1 = note
    #             Note.find @ids[1], (err, note) =>
    #                 should.not.exist err
    #                 note.id.should.equal @ids[1]
    #                 note.content.should.equal "new note 02"
    #                 @note2 = note
    #                 Note.find @ids[2], (err, note) =>
    #                     should.not.exist err
    #                     note.id.should.equal @ids[2]
    #                     note.content.should.equal "new note 03"
    #                     @note3 = note
    #                     done()


describe "Update", ->

    before (done) ->
        data =
            title: "my note"
            content: "my content"
            docType: "Note"

        client.post 'data/321/', data, (error, response, body) ->
            done()
        @note = new Note data

    after (done) ->
        client.del "data/321/", (error, response, body) ->
            done()


    describe "Try to Update a Document that doesn't exist", ->
        after ->
            @err = null

        it "When I update a document with id 123", (done) ->
            @note.id = "123"
            @note.save (err) =>
                @err = err
                done()

        it "Then an error is returned", ->
            should.exist @err

    describe "Update a Document", ->

        it "When I update document with id 321", (done) ->
            @note.id = "321"
            @note.title = "my new title"
            @note.save (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

        it "And the old document must have been replaced in DB", (done) ->
            Note.find @note.id, (err, updatedNote) =>
                should.not.exist err
                updatedNote.id.should.equal "321"
                updatedNote.title.should.equal "my new title"
                done()


describe "Update attributes", ->

    before (done) ->
        data =
            title: "my note"
            content: "my content"
            docType: "Note"

        client.post 'data/321/', data, (error, response, body) ->
            done()
        @note = new Note data

    after (done) ->
        client.del "data/321/", (error, response, body) ->
            done()


    describe "Try to update attributes of a document that doesn't exist", ->
        after ->
            @err = null

        it "When I update a document with id 123", (done) ->
            @note.id = "123"
            @note.updateAttributes title: "my new title", (err) =>
                @err = err
                done()

        it "Then an error is returned", ->
            should.exist @err

    describe "Update a Document", ->

        it "When I update document with id 321", (done) ->
            @note.id = "321"
            @note.updateAttributes title: "my new title", (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

        it "And the old document must have been replaced in DB", (done) ->
            Note.find @note.id, (err, updatedNote) =>
                should.not.exist err
                updatedNote.id.should.equal "321"
                updatedNote.title.should.equal "my new title"
                done()


# CHANGES : updateOrCreate removed, not used in cozy application

# describe "Upsert attributes", ->

#     after (done) ->
#         client.del "data/654/", (error, response, body) ->
#             done()

#     describe "Upsert a non existing document", ->
#         it "When I upsert document with id 654", (done) ->
#             @data =
#                 id: "654"
#                 title: "my note"
#                 content: "my content"

#             Note.updateOrCreate @data, (err) =>
#                 @err = err
#                 done()

#         it "Then no error should be returned.", ->
#             should.not.exist @err

#         it "And the document with id 654 should exist in Database", (done) ->
#             Note.find @data.id, (err, updatedNote) =>
#                 should.not.exist err
#                 updatedNote.id.should.equal "654"
#                 updatedNote.title.should.equal "my note"
#                 done()

#     describe "Upsert an existing Document", ->

#         it "When I upsert document with id 654", (done) ->
#             @data =
#                 id: "654"
#                 title: "my new title"

#             Note.updateOrCreate @data, (err, note) =>
#                 should.not.exist note
#                 @err = err
#                 done()

#         it "Then no data should be returned", ->
#             should.not.exist @err

#         it "And the document with id 654 should be updated", (done) ->
#             Note.find @data.id, (err, updatedNote) =>
#                 should.not.exist err
#                 updatedNote.id.should.equal "654"
#                 updatedNote.title.should.equal "my new title"
#                 done()


describe "Delete", ->
    before (done) ->
        client.post 'data/321/', {
            title: "my note"
            content: "my content"
            docType: "Note"
            } , (error, response, body) ->
            done()

    after (done) ->
        client.del "data/321/", (error, response, body) ->
            client.del "data/987/", (error, response, body) ->
                done()


    describe "Deletes a document that is not in Database", ->

        it "When I delete Document with id 123", (done) ->
            note = new Note id:123
            note.destroy (err) =>
                @err = err
                done()

        it "Then an error should be returned", ->
            should.exist @err

    describe "Deletes a document from database", ->

        it "When I delete document with id 321", (done) ->
            note = new Note id:321
            note.destroy (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

        it "And Document with id 321 shouldn't exist in Database", (done) ->
            Note.exists 321, (err, isExist) =>
                isExist.should.not.be.ok
                done()


### Indexation ###

ids = []
dragonNoteId = "0"

createNoteFunction = (title, content, author) ->
    (callback) ->
        if author? then authorId = author.id else authorId = null
        data =
            title: title
            content: content
            author: authorId

        Note.create data, (err, note) ->
            return done err if err
            ids.push note.id
            dragonNoteId = note.id if title is "Note 02"

            note.index ["title", "content"], (err) ->
                callback()

createTaskFunction = (description) ->
    (callback) ->
        client.post 'data/', {
            description: "description"
            docType: "task"
        } , (error, response, body) ->
            callback()

fakeServer = (json, code=200, callback=null) ->
    http.createServer (req, res) ->
        body = ""
        req.on 'data', (chunk) ->
            body += chunk
        req.on 'end', ->
            if callback?
                data = JSON.parse body if body? and body.length > 0
                code = callback req.url, data
            res.writeHead code, 'Content-Type': 'application/json'

            res.end(JSON.stringify json)

deleteNoteFunction = (id) ->
    (callback) ->
        client.del "data/#{id}/", (err) -> callback()

describe "Search features", ->

    before (done) ->
        client.post 'data/321/', {
            title: "my note"
            content: "my content"
            docType: "Note"
            } , (error, response, body) ->
                done()

    after (done) ->
        funcs = []
        for id in ids
            funcs.push deleteNoteFunction(id)
        async.series funcs, ->
            ids = []
            done()


    describe "index", ->

        before (done) ->
            client.del "data/index/clear-all/", (err, response) ->
                done()

        it "When given I index four notes", (done) ->
            async.series [
                createNoteFunction "Note 01", "little stories begin"
                createNoteFunction "Note 02", "great dragons are coming"
                createNoteFunction "Note 03", "small hobbits are afraid"
                createNoteFunction "Note 04", "such as humans"
            ], =>
                data = ids: [dragonNoteId]
                @indexer = fakeServer data, 200, (url, body) ->
                    if url is '/index/'
                        should.exist body.fields
                        should.exist body.doc
                        should.exist body.doc.docType
                        200
                    else if url is '/search/'
                        should.exist body.query
                        body.query.should.equal "dragons"
                        200
                    else 204
                @indexer.listen 9092
                setTimeout done, 500


        it "And I send a request to search the notes containing dragons", \
                (done) ->
            Note.search "dragons", (err, notes) =>
                return done err if err
                @notes = notes
                @indexer.close()
                done()

        it "Then result is the second note I created", ->

            @notes.length.should.equal 1
            @notes[0].title.should.equal "Note 02"
            @notes[0].content.should.equal "great dragons are coming"


### Attachments ###

describe "Attachments", ->

    before (done) ->
        @note = new Note id: 321
        data =
            title: "my note"
            content: "my content"
            docType: "Note"

        client.post 'data/321/', data, (error, response, body) ->
            done()

    after (done) ->
        client.del "data/321/", (error, response, body) ->
            done()

    describe "Add an attachment", ->

        it "When I add an attachment", (done) ->
            @note.attachFile TESTFILE, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

    describe "Retrieve an attachment", ->

        it "When I claim this attachment", (done) ->
            @timeout 10000
            stream = @note.getFile TESTFILENAME, -> done()
            stream.pipe fs.createWriteStream(TESTFILEOUT)

        it "Then I got the same file I attached before", ->
            fileStats = fs.statSync(TESTFILE)
            resultStats = fs.statSync(TESTFILEOUT)
            resultStats.size.should.equal fileStats.size

    describe "Remove an attachment", ->

        it "When I remove this attachment", (done) ->
            @note.removeFile TESTFILENAME, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

        it "When I claim this attachment", (done) ->
            stream = @note.getFile TESTFILENAME, (err) =>
                @err = err
                done()
            stream.pipe fs.createWriteStream(TESTFILEOUT)


        it "Then I got an error", ->
            should.exist @err


checkNoError = ->
    it "Then no error should be returned", ->
        should.not.exist @err


checkError = ->
    it "Then error should be returned", ->
        should.exist  @err

describe "Requests", ->

    before (done) ->
        async.series [
            createNoteFunction "Note 01", "little stories begin"
            createNoteFunction "Note 02", "great dragons are coming"
            createNoteFunction "Note 03", "small hobbits are afraid"
            createNoteFunction "Note 04", "such as humans"
            createTaskFunction "Task 01"
            createTaskFunction "Task 02"
            createTaskFunction "Task 03"
        ], ->
            done()

    after (done) ->
        funcs = []
        for id in ids
            funcs.push deleteNoteFunction(id)
        async.series funcs, ->
            ids = []
            done()

    describe "index", ->
    describe "View creation", ->

        describe "Creation of the first view + design document creation", ->

            it "When I send a request to create view every_docs", (done) ->
                delete @err
                @map = (doc) ->
                    emit doc._id, doc
                    return
                Note.defineRequest "every_notes", @map, (err) ->
                    should.not.exist err
                    done()

            checkNoError()

    describe "Access to a view without option", ->

        describe "Access to a non existing view", ->

            it "When I send a request to access view dont-exist", (done) ->
                delete @err
                Note.request "dont-exist", (err, notes) =>
                    @err = err
                    should.exist err
                    done()

            checkError()


        describe "Access to an existing view : every_notes", (done) ->

            it "When I send a request to access view every_docs", (done) ->
                delete @err
                Note.request "every_notes", (err, notes) =>
                    @notes = notes
                    done()

            it "Then I should have 4 documents returned", ->
                @notes.should.have.length 4

        describe "Access to a doc from a view : every_notes", (done) ->

            it "When I send a request to access doc 3 from every_docs", \
                    (done) ->
                delete @err
                Note.request "every_notes", {key: ids[3]}, (err, notes) =>
                    @notes = notes
                    done()

            it "Then I should have 1 documents returned", ->
                @notes.should.have.length 1
                @notes[0].id.should.equal ids[3]

    describe "Reduced View creation", ->

        it "When I send a request to create view reduced", (done) ->
            delete @err
            view =
                reduce: (key, values, rereduce) -> true
                map: (doc) ->
                    emit doc._id, doc
                    return

            Note.defineRequest "reduced", view, (err) ->
                should.not.exist err
                done()

        it "When I send a request to access view reduced", (done) ->
            Note.rawRequest "reduced", group_level: 1, (err, notes) =>
                should.not.exist err
                notes.should.have.length 4
                notes[0].value.should.equal true
                done()

        it "When I send a request to create view reduced_string", (done) ->
            delete @err
            view =
                reduce: '_count'
                map: (doc) ->
                    emit doc._id, doc
                    return

            Note.defineRequest "reduced_string", view, (err) ->
                should.not.exist err
                done()


        it "When I send a request to access view every_docs", (done) ->
            Note.rawRequest "reduced_string", group_level: 1, (err, notes) =>
                should.not.exist err
                notes.should.have.length 4
                notes[0].value.should.equal 1
                done()

    describe "Deletion of docs through requests", ->

        describe "Delete a doc from a view : every_notes", (done) ->

            it "When I send a request to delete a doc from every_docs", \
                    (done) ->
                Note.requestDestroy "every_notes", {key: ids[3]}, (err) ->
                    should.not.exist err
                    done()

            it "And I send a request to access view every_docs", (done) ->
                delete @err
                delete @notes
                Note.request "every_notes", {key: ids[3]}, (err, notes) =>
                    @notes = notes
                    done()

            it "Then I should have 0 documents returned", ->
                @notes.should.have.length 0

            it "And other documents are still there", (done) ->
                Note.request "every_notes", (err, notes) =>
                    should.not.exist err
                    notes.should.have.length 3
                    done()

        describe "Delete all doc from a view : every_notes", (done) ->

            it "When I delete all docs from every_docs", (done) ->
                Note.requestDestroy "every_notes", (err) ->
                    should.not.exist err
                    done()

            it "And I send a request to grab all docs from every_docs", \
                    (done) ->
                delete @err
                delete @notes
                Note.request "every_notes", (err, notes) =>
                    @notes = notes
                    done()

            it "Then I should have 0 documents returned", ->
                @notes.should.have.length 0

    describe "Deletion of an existing view", ->

        it "When I send a request to delete view every_notes", (done) ->
            Note.removeRequest "every_notes", (err) ->
                should.not.exist err
                done()



        # Following DS commit 8e43fc66
        # the request will be kept in case another app use it

#### Relations ###

#describe "Relations", ->

    #before (done) ->
        #Author.create name: "John", (err, author) =>
            #@author = author
            #async.series [
                #createNoteFunction "Note 01", "little stories begin", author
                #createNoteFunction "Note 02", "great dragons are coming", author
                #createNoteFunction "Note 03", "small hobbits are afraid", author
                #createNoteFunction "Note 04", "such as humans", null
            #], ->
                #done()

    #after (done) ->
        #funcs = []
        #for id in ids
            #funcs.push deleteNoteFunction(id)
        #async.series funcs, ->
            #ids = []
            #if author?
                #@author.destroy ->
                    #done()
            #else
                #done()

    #describe "Has many relation", ->

        #it "When I require all notes related to given author", (done) ->
            #@author.notes (err, notes) =>
                #should.not.exist err
                #@notes = notes
                #done()

        #it "Then I have three notes", ->
            #should.exist @notes
            #@notes.length.should.equal 3

    ###describe "Send mail", ->

        describe "Send common mail", ->

            it "When I send the mail", (done) ->
                data =
                    to: "test@cozycloud.cc"
                    from: "Cozy-test <test@cozycloud.cc>"
                    subject: "Test jugglingdb"
                    content: "Content of mail"
                CozyAdapter.sendMail data, (err) =>
                    @err = err
                    done()

            it "Then no error is returned", ->
                should.not.exist @err

        describe "Send mail to user", ->

            it "When I send the mail", (done) ->
                data =
                    from: "Cozy-test <test@cozycloud.cc>"
                    subject: "Test jugglingdb"
                    content: "Content of mail"
                CozyAdapter.sendMailToUser data, (err) =>
                    @err = err
                    done()

            it "Then no error is returned", ->
                should.not.exist @err

        describe "Send mail from user", ->

            it "When I send the mail", (done) ->
                data =
                    to: "test@cozycloud.cc"
                    subject: "Test jugglingdb"
                    content: "Content of mail"
                CozyAdapter.sendMailFromUser data, (err) =>
                    @err = err
                    done()

            it "Then no error is returned", ->
                should.not.exist @err###

