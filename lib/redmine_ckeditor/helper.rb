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
          $(doc).on("paste", copyImageFromClipboardCKEditor);
          $(doc).on("drop", copyImageFromDrop);
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

        function rebindCKEditorPasteEventsForAllInstances() {
          const instanceKeys = Object.keys(CKEDITOR.instances);
          if (instanceKeys.length === 0) return;

          instanceKeys.forEach(editorName => {
            const editor = CKEDITOR.instances[editorName];
            if (!editor) return;

            const iframe = $(editor.container.$).find('iframe.cke_wysiwyg_frame');
            if (!iframe.length) return;

            const doc = iframe[0].contentDocument || iframe[0].contentWindow.document;
            if (!doc) return;

            const wikiElem = $(doc).find(".wiki");
            if (!wikiElem.length) return;

            if (typeof copyImageFromClipboardCKEditor !== 'function') return;
            if (typeof copyImageFromDrop !== 'function') return;
            if (typeof addInlineAttachmentMarkupCKEditor !== 'function') return;

            const events = $._data(wikiElem[0], 'events') || {};
            const hasPaste = events.paste && events.paste.some(e => e.handler === copyImageFromClipboardCKEditor);
            const hasDrop = events.drop && events.drop.some(e => e.handler === copyImageFromDrop);

            if (!hasPaste) {
              wikiElem.on("paste", copyImageFromClipboardCKEditor);
            }

            if (!hasDrop) {
              wikiElem.on("drop", copyImageFromDrop);
            }

            if (window.addInlineAttachmentMarkup !== addInlineAttachmentMarkupCKEditor) {
              addInlineAttachmentMarkup = addInlineAttachmentMarkupCKEditor;
            }
          });
        }

        // check every 200ms if paste and drop function is binded, otherwise bind it
        // this is helpfull if other plugins like redmine_issue_templates reloads parts of the html
        setInterval(rebindCKEditorPasteEventsForAllInstances, 250);

      EOT
    end
  end
end
