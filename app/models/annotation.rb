class Annotation < ActiveRecord::Base
  attr_accessible :ann_id, :lang, :paragraph_idx, :selected_text, :text_idx, :translation, :url, :user_id, :article_id
  belongs_to :article
end
