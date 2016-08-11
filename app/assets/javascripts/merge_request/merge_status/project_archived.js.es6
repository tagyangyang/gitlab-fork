const projectArchived = {
  props: ['ci', 'mergeRequest', 'project'],
  template: `<div>
              <h4>Project is archived</h4>
              <p>This merge request cannot be merged because archived projects cannot be written to.</p>
            </div>`
};
