class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext


  def message(message)
    # message can be also accessed via instance method
    message == self.payload # true
    # store_message(message['text'])
  end

  def rename(*)
    # set context for the next message
    save_context :rename
    respond_with :message, text: 'What name do you like?'
  end

  # register context handlers to handle this context
  context_handler :rename do |*words|
    update_name words[0]
    respond_with :message, text: 'Renamed!'
  end

  # You can do it in other way:
  def rename(name = nil, *)
    if name
      update_name name
      respond_with :message, text: 'Renamed!'
    else
      save_context :rename
      respond_with :message, text: 'What name do you like?'
    end
  end

  # This will call #rename like if it is called with message '/rename %text%'
  context_handler :rename

  # If you have a lot of such methods you can call this method
  # to use context value as action name for all contexts which miss handlers:
  context_to_action!
end
