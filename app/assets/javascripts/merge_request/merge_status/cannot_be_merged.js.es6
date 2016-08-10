const mergeStatusCannotBeMerged = {
  template: ` <div>
                <h4 class="has-conflicts">
                  <i class="fa fa-exclamation-triangle"></i>
                  This merge request contains merge conflicts
                </h4>
                <p>
                  Please resolve these conflicts or
                  <a class="how_to_merge_link vlink" data-toggle="modal" href="#modal_merge_info">merge this request manually</a>.
                </p>
              <div>`
};
