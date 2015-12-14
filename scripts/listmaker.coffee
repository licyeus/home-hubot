require('dotenv').load()

request = require 'superagent'
_       = require 'lodash'
uuid    = require 'node-uuid'

TODOIST_TOKEN = process.env.TODOIST_TOKEN

clean_urls = (str) -> str.replace(/http[s]?:\/\/(www\.)/g,'') # clean url so that slack doesn't unfurl (expand) the link

call_todoist = (on_success) ->
  request.get('https://todoist.com/API/v6/sync')
    .query({ token: TODOIST_TOKEN, seq_no: 0, resource_types: JSON.stringify(['projects','items']) })
    .end (err, res) ->
      return console.log 'error!', err if err

      on_success(res)

get_items = (list_name, cb) ->
  call_todoist (res) ->
    project = _.find(res.body.Projects, (project) -> project.name.toLowerCase() == list_name)
    return cb("Unable to find project '#{list_name}'") if !project

    project_items = _.filter(res.body.Items, (item) -> item.project_id == project.id)

    heading = "List '#{project.name}' has #{project_items.length} items:\n"
    output = _.reduce(project_items, (acc, item) ->
      acc += "#{item.content}\n"
    , heading)

    cb(output)

add_item = (list_name, item, cb) ->
  call_todoist (res) ->
    project = _.find(res.body.Projects, (project) -> project.name.toLowerCase() == list_name)
    return cb("Unable to find project '#{list_name}'") if !project

    item = clean_urls(item)

    request.get('https://todoist.com/API/v6/sync')
      .query({ token: TODOIST_TOKEN, seq_no: 0 })
      .query({
        commands: JSON.stringify([
          {
            type: 'item_add',
            uuid: uuid.v4(),
            temp_id: uuid.v4(),
            args: {
              project_id: project.id,
              content: item
            }
          }
        ])
      })
      .end (err, res) ->
        return console.log 'error!', err if err
        console.log JSON.stringify(res.body, null, 4)
        cb("added '#{item}' to #{project.name} list")

 module.exports = (robot) ->
    robot.hear /^list (.*)/i, (res) ->
      list_name = res.match[1]
      get_items list_name, (output) => res.send output

    robot.hear /^add (.*?) to (.*)/i, (res) ->
      item = res.match[1]
      list_name = res.match[2]
      add_item list_name, item, (output) => res.send output

#    robot.hear /^url for (.*) list/i, (res) ->
#      list_name = res.match[1]
#      get_url_for_list (output) => res.send output