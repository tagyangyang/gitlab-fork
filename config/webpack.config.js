'use strict';

var fs = require('fs');
var path = require('path');
var webpack = require('webpack');
var StatsPlugin = require('stats-webpack-plugin');
var CompressionPlugin = require('compression-webpack-plugin');
var BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

var ROOT_PATH = path.resolve(__dirname, '..');
var IS_PRODUCTION = process.env.NODE_ENV === 'production';
var IS_DEV_SERVER = process.argv[1].indexOf('webpack-dev-server') !== -1;
var DEV_SERVER_PORT = parseInt(process.env.DEV_SERVER_PORT, 10) || 3808;
var DEV_SERVER_LIVERELOAD = process.env.DEV_SERVER_LIVERELOAD !== 'false';
var WEBPACK_REPORT = process.env.WEBPACK_REPORT;

var config = {
  context: path.join(ROOT_PATH, 'app/assets/javascripts'),
  entry: {
    common:               './commons/index.js',
    common_vue:           ['vue', './vue_shared/common_vue.js'],
    common_d3:            ['d3'],
    main:                 './main.js',
    blob:                 './blob_edit/blob_bundle.js',
    boards:               './boards/boards_bundle.js',
    cycle_analytics:      './cycle_analytics/cycle_analytics_bundle.js',
    commit_pipelines:     './commit/pipelines/pipelines_bundle.js',
    diff_notes:           './diff_notes/diff_notes_bundle.js',
    environments:         './environments/environments_bundle.js',
    environments_folder:  './environments/folder/environments_folder_bundle.js',
    filtered_search:      './filtered_search/filtered_search_bundle.js',
    graphs:               './graphs/graphs_bundle.js',
    groups_list:          './groups_list.js',
    issuable:             './issuable/issuable_bundle.js',
    merge_conflicts:      './merge_conflicts/merge_conflicts_bundle.js',
    merge_request_widget: './merge_request_widget/ci_bundle.js',
    monitoring:           './monitoring/monitoring_bundle.js',
    network:              './network/network_bundle.js',
    notebook_viewer:      './blob/notebook_viewer.js',
    sketch_viewer:        './blob/sketch_viewer.js',
    pdf_viewer:           './blob/pdf_viewer.js',
    profile:              './profile/profile_bundle.js',
    protected_branches:   './protected_branches/protected_branches_bundle.js',
    snippet:              './snippet/snippet_bundle.js',
    stl_viewer:           './blob/stl_viewer.js',
    terminal:             './terminal/terminal_bundle.js',
    u2f:                  ['vendor/u2f'],
    users:                './users/users_bundle.js',
    vue_pipelines:        './vue_pipelines_index/index.js',
    issue_show:           './issue_show/index.js',
    group:                './group.js',
  },

  output: {
    path: path.join(ROOT_PATH, 'public/assets/webpack'),
    publicPath: '/assets/webpack/',
    filename: IS_PRODUCTION ? '[name].[chunkhash].bundle.js' : '[name].bundle.js'
  },

  devtool: 'cheap-module-source-map',

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|vendor\/assets)/,
        loader: 'babel-loader'
      },
      {
        test: /\.svg$/,
        use: 'raw-loader'
      }, {
        test: /\.(worker.js|pdf)$/,
        exclude: /node_modules/,
        loader: 'file-loader',
      },
    ]
  },

  plugins: [
    // manifest filename must match config.webpack.manifest_filename
    // webpack-rails only needs assetsByChunkName to function properly
    new StatsPlugin('manifest.json', {
      chunkModules: false,
      source: false,
      chunks: false,
      modules: false,
      assets: true
    }),

    // prevent pikaday from including moment.js
    new webpack.IgnorePlugin(/moment/, /pikaday/),

    // fix legacy jQuery plugins which depend on globals
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
    }),

    // use deterministic module ids in all environments
    IS_PRODUCTION ?
      new webpack.HashedModuleIdsPlugin() :
      new webpack.NamedModulesPlugin(),

    // create cacheable common library bundle for all vue chunks
    new webpack.optimize.CommonsChunkPlugin({
      name: 'common_vue',
      chunks: [
        'boards',
        'commit_pipelines',
        'cycle_analytics',
        'diff_notes',
        'environments',
        'environments_folder',
        'issuable',
        'merge_conflicts',
        'notebook_viewer',
        'pdf_viewer',
        'vue_pipelines',
      ],
      minChunks: function(module, count) {
        return module.resource && (/vue_shared/).test(module.resource);
      },
    }),

    // create cacheable common library bundle for all d3 chunks
    new webpack.optimize.CommonsChunkPlugin({
      name: 'common_d3',
      chunks: [
        'graphs',
        'users',
        'monitoring',
      ],
    }),

    // create cacheable common library bundles
    new webpack.optimize.CommonsChunkPlugin({
      names: ['main', 'common', 'runtime'],
    }),
  ],

  resolve: {
    extensions: ['.js'],
    alias: {
      '~':              path.join(ROOT_PATH, 'app/assets/javascripts'),
      'emojis':         path.join(ROOT_PATH, 'fixtures/emojis'),
      'empty_states':   path.join(ROOT_PATH, 'app/views/shared/empty_states'),
      'icons':          path.join(ROOT_PATH, 'app/views/shared/icons'),
      'vendor':         path.join(ROOT_PATH, 'vendor/assets/javascripts'),
      'vue$':           'vue/dist/vue.esm.js',
    }
  }
}

if (IS_PRODUCTION) {
  config.devtool = 'source-map';
  config.plugins.push(
    new webpack.NoEmitOnErrorsPlugin(),
    new webpack.LoaderOptionsPlugin({
      minimize: true,
      debug: false
    }),
    new webpack.optimize.UglifyJsPlugin({
      sourceMap: true
    }),
    new webpack.DefinePlugin({
      'process.env': { NODE_ENV: JSON.stringify('production') }
    }),
    new CompressionPlugin({
      asset: '[path].gz[query]',
    })
  );
}

if (IS_DEV_SERVER) {
  config.devtool = 'cheap-module-eval-source-map';
  config.devServer = {
    port: DEV_SERVER_PORT,
    headers: { 'Access-Control-Allow-Origin': '*' },
    stats: 'errors-only',
    inline: DEV_SERVER_LIVERELOAD
  };
  config.output.publicPath = '//localhost:' + DEV_SERVER_PORT + config.output.publicPath;
}

if (WEBPACK_REPORT) {
  config.plugins.push(
    new BundleAnalyzerPlugin({
      analyzerMode: 'static',
      generateStatsFile: true,
      openAnalyzer: false,
      reportFilename: path.join(ROOT_PATH, 'webpack-report/index.html'),
      statsFilename: path.join(ROOT_PATH, 'webpack-report/stats.json'),
    })
  );
}

module.exports = config;
