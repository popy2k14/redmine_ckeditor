module RedmineCkeditor
  module Helper
    def ckeditor_javascripts
      root = RedmineCkeditor.assets_root
      plugin_script = RedmineCkeditor.plugins.map {|name|
        "CKEDITOR.plugins.addExternal('#{name}', '#{root}/ckeditor-contrib/plugins/#{name}/');"
      }.join

      javascript_tag("CKEDITOR_BASEPATH = '#{root}/ckeditor/';") +
      javascript_include_tag("application", :plugin => "redmine_ckeditor") +
      javascript_tag(<<-EOT)
        #{plugin_script}

        CKEDITOR.on("instanceReady", function(event) {
          let editor = event.editor;
          let textarea = document.getElementById(editor.name);

          editor.on("change", function() {
            textarea.value = editor.getSnapshot();
          });

          let iframe_contaner=$(editor.element.getNext())[0].find("iframe")
          doc=$(iframe_contaner.$).contents().find(".wiki")
          setTimeout(function() {
            $(doc).on("paste", copyImageFromClipboardCKEditor);
            $(doc).on("drop", copyImageFromDrop);
          },2000)

        });

        $(window).on("beforeunload", function() {
          for (var id in CKEDITOR.instances) {
            if (CKEDITOR.instances[id].checkDirty()) {
              return #{l(:text_warn_on_leaving_unsaved).inspect};
            }
          }
        });
        $(document).on("submit", "form", function() {
          for (var id in CKEDITOR.instances) {
            CKEDITOR.instances[id].resetDirty();
          }
        });
        setTimeout(function() {
          addInlineAttachmentMarkupOrg = addInlineAttachmentMarkup;
          addInlineAttachmentMarkup = addInlineAttachmentMarkupCKEditor;
          $('.icon-download').each(function(){
            m = $(this).attr('href').match(new RegExp('/attachments/download/(.+)/'));
            if(m) {
              a_tag = $('<a class="icon-only icon-copy" title="copy" href="/attachments/download/'+m[1]+
                        '" onclick="copyAttachmentURL('+m[1]+');return false;"></a>');
              $(this).before(a_tag[0]);
             }
          });
        }, 2000);



        $(document).on("click", ".cke_button__source", function(){

          setTimeout(function() {
            $('iframe').contents().find('.wiki').on("paste", copyImageFromClipboardCKEditor);
            $('iframe').contents().find('.wiki').on("drop", copyImageFromDrop);
          }, 2000);

        });
      EOT
    end
  end
end
