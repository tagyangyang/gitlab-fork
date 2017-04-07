import MRWidgetAuthor from '../../components/mr_widget_author';

export default {
  name: 'MRWidgetMergeWhenPipelineSucceeds',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  components: {
    'mr-widget-author': MRWidgetAuthor,
  },
  data() {
    return {
      isCancellingAutoMerge: false,
      isRemovingSourceBranch: false,
    };
  },
  computed: {
    canRemoveSourceBranch() {
      const { shouldRemoveSourceBranch, canRemoveSourceBranch,
        mergeUserId, currentUserId } = this.mr;

      return !shouldRemoveSourceBranch && canRemoveSourceBranch && mergeUserId === currentUserId;
    },
  },
  methods: {
    cancelAutomaticMerge() {
      this.isCancellingAutoMerge = true;
      this.service.cancelAutomaticMerge()
        .then(res => res.json())
        .then((res) => {
          this.mr.setData(res); // TODO: Should find a better way to update store.
        });
        // TODO: Handle catch here.
    },
    removeSourceBranch() {
      const options = {
        sha: this.mr.sha,
        merge_when_pipeline_succeeds: true,
        should_remove_source_branch: true,
      };

      this.isRemovingSourceBranch = true;
      this.service.mergeResource.save(options); // TODO: Response and error handling, widget update
    },
  },
  template: `
    <div class="mr-widget-body">
      <h4>
        Set by
        <mr-widget-author :author="mr.setToMWPSBy" />
        to be merged automatically when the pipeline succeeds.
        <button
          v-if="mr.canCancelAutomaticMerge"
          @click="cancelAutomaticMerge"
          :disabled="isCancellingAutoMerge"
          type="button" class="btn btn-xs btn-default">
          <i
            v-if="isCancellingAutoMerge"
            class="fa fa-spinner fa-spin" aria-hidden="true"></i>
            Cancel automatic merge</button>
      </h4>
      <section>
        <p>The changes will be merged into
          <a :href="mr.targetBranchPath" class="label-branch">
            {{mr.targetBranch}}
          </a>
        </p>
        <p v-if="mr.shouldRemoveSourceBranch">The source branch will be removed.</p>
        <p v-else>
          The source branch will not be removed.
          <button
            v-if="canRemoveSourceBranch"
            @click="removeSourceBranch"
            type="button" class="btn btn-xs btn-default">
            <i
            v-if="isRemovingSourceBranch"
            class="fa fa-spinner fa-spin" aria-hidden="true"></i>
            Remove source branch</button>
        </p>
      </section>
    </div>
  `,
};
