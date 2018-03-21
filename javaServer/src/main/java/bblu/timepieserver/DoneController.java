package bblu.timepieserver;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DoneController {
    @RequestMapping(value= "/done", method = RequestMethod.GET)
    public String hello(){
        return "hello timepie server!";
    }

    @RequestMapping(value="/done", method = RequestMethod.POST)
    public void postData(){

    }
}
