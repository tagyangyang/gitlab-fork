import eventHub from '../event_hub';

export default {
  name: 'RecentSearchesDropdownContent',

  props: {
    items: {
      type: Array,
      required: true,
    },
  },

  computed: {
    processedItems() {
      return this.items.map((item) => {
        const { tokens, searchToken }
          = gl.FilteredSearchTokenizer.processTokens(item);

        const resultantTokens = tokens.map(token => ({
          prefix: `${token.key}:`,
          suffix: `${token.symbol}${token.value}`,
        }));

        return {
          text: item,
          tokens: resultantTokens,
          searchToken,
        };
      });
    },
    hasItems() {
      return this.items.length > 0;
    },
  },

  methods: {
    onItemActivated(text) {
      eventHub.$emit('recentSearchesItemSelected', text);
    },
    onRequestClearRecentSearches(e) {
      // Stop the dropdown from closing
      e.stopPropagation();

      eventHub.$emit('requestClearRecentSearches');
    },
  },

  template: `
    <div>
      <ul v-if="hasItems">
        <li
          v-for="(item, index) in processedItems"
          :key="index">
          <button
            type="button"
            class="filtered-search-history-dropdown-item"
            @click="onItemActivated(item.text)">
            <span>
              <span
                v-for="(token, tokenIndex) in item.tokens"
                class="filtered-search-history-dropdown-token">
                <span class="name">{{ token.prefix }}</span><span class="value">{{ token.suffix }}</span>
              </span>
            </span>
            <span class="filtered-search-history-dropdown-search-token">
              {{ item.searchToken }}
            </span>
          </button>
        </li>
        <li class="divider"></li>
        <li>
          <button
            type="button"
            class="filtered-search-history-clear-button"
            @click="onRequestClearRecentSearches($event)">
            Clear recent searches
          </button>
        </li>
      </ul>
      <div
        v-else
        class="dropdown-info-note">
        You don't have any recent searches
      </div>
    </div>
  `,
};
