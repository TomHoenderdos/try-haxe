
import api.Program;
import haxe.remoting.HttpAsyncConnection;
import js.codemirror.CodeMirror;
import js.JQuery;

using js.bootstrap.Button;

class Editor {

	var cnx : HttpAsyncConnection;
	
	var program : Program;
	var output : Output;
	
	var gateway : String;
	
	var form : JQuery;
	var haxeSource : CodeMirror;
	var jsSource : CodeMirror;
	var runner : JQuery;
	var messages : JQuery;
	var compileBtn : JQuery;

	public function new(){

		CodeMirror.commands.autocomplete = autocomplete;

  		haxeSource = CodeMirror.fromTextArea( cast new JQuery("textarea[name='hx-source']").get(0) , {
			mode : "javascript",
			theme : "cobalt",
			lineWrapping : true,
			lineNumbers : true,
			extraKeys : {
				"Ctrl-Space" : "autocomplete"
			}
		} );
		
		jsSource = CodeMirror.fromTextArea( cast new JQuery("textarea[name='js-source']").get(0) , {
			mode : "javascript",
			theme : "cobalt",
			lineWrapping : true,
			lineNumbers : true,
			readOnly : true
		} );
		
		runner = new JQuery("iframe[name='js-run']");
		messages = new JQuery(".messages");
		compileBtn = new JQuery(".compile-btn");

		new JQuery("body").bind("keyup", onKey );

		new JQuery("a[data-toggle='tab']").bind( "shown", function(e){
			jsSource.refresh();
		});
		
		compileBtn.bind( "click" , compile );

		gateway = new JQuery("body").data("gateway");
		cnx = HttpAsyncConnection.urlConnect(gateway);

		program = {
			uid : null,
			main : {
				name : "Test",
				source : haxeSource.getValue()
			},
			target : JS( "test" )
		}
  	}

  	public function autocomplete( cm : CodeMirror ){
  		updateProgram();
  		var pos = cm.getCursor();

  		cnx.Compiler.autocomplete.call( [ program , pos ] , function( comps ) displayCompletions( cm , comps ) );
  	}

  	public function displayCompletions(cm : CodeMirror , completions : Array<String> ) {
  		var comps = [];

  		CodeMirror.simpleHint( cm , function(cm){ return {
  			list : completions,
  			from : cm.getCursor(),
  			to : cm.getCursor()
  		}; } );
  	}

  	public function onKey( e : JqEvent ){
  		if( e.ctrlKey && e.keyCode == 13 ){
  			compile(e);
  		}
  	}

  	public function compile(?e){
  		if( e != null ) e.preventDefault();
  		compileBtn.buttonLoading();
  		updateProgram();
  		cnx.Compiler.compile.call( [program] , onCompile );
  	}

  	function updateProgram(){
  		program.main.source = haxeSource.getValue();
  	}

  	public function run(){
  		if( output.success ){
	  		var run = gateway + "?run=" + output.uid + "&r=" + Std.string(Math.random());
	  		runner.attr("src" , run );
  		}else{
  			runner.attr("src" , "about:blank" );
  		}
  	}

  	public function onCompile( o : Output ){

  		var errLine = ~/([^:]*):([0-9]+): characters ([0-9]+)-([0-9]+) :(.*)/g;
  		
  		output = o;
  		program.uid = output.uid;
  		
  		jsSource.setValue( output.source );
  		
  		if( output.success ){
  			messages.html( "<div class='alert alert-success'><h4 class='alert-heading'>" + output.message + "</h4><pre>"+output.stderr+"</pre></div>" );
  		}else{
  			messages.html( "<div class='alert alert-error'><h4 class='alert-heading'>" + output.message + "</h4><pre>"+output.stderr+"</pre></div>" );
  		}

  		compileBtn.buttonReset();

  		run();

  	}

}